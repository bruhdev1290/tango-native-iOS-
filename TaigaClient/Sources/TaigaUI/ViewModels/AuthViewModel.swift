import Foundation
import Observation
import TaigaCore
import AuthenticationServices
import UIKit

@Observable
public final class AuthViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case authenticated(AuthToken)
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public let gitHubConfig: GitHubOAuthConfig

    private let authService: AuthService

    public init(
        authService: AuthService,
        gitHubConfig: GitHubOAuthConfig = .default
    ) {
        self.authService = authService
        self.gitHubConfig = gitHubConfig
        Swift.Task { [weak self] in
            guard let self else { return }
            if let cached = await authService.currentToken() {
                await MainActor.run {
                    self.state = .authenticated(cached)
                }
            }
        }
    }

    @MainActor
    public var token: AuthToken? {
        if case .authenticated(let token) = state {
            return token
        }
        return nil
    }

    @MainActor
    public func login(username: String, password: String) async {
        state = .loading
        do {
            let token = try await authService.login(username: username, password: password)
            state = .authenticated(token)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    public func loginWithGitHub() async {
        guard gitHubConfig.isEnabled else {
            state = .failed("GitHub OAuth not configured. Please set up GitHub Client ID.")
            return
        }

        state = .loading

        do {
            let code = try await authenticateWithGitHub()
            let token = try await authService.loginWithGitHub(code: code)
            state = .authenticated(token)
        } catch let error as GitHubAuthError {
            if error == .cancelled {
                state = .idle
            } else {
                state = .failed(error.localizedDescription)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    public func logout() {
        Swift.Task {
            await authService.logout()
        }
        state = .idle
    }

    @MainActor
    public func resetSession() {
        logout()
    }

    // MARK: - GitHub OAuth

    @MainActor
    private func authenticateWithGitHub() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let authURL = URL(string: "https://github.com/login/oauth/authorize?client_id=\(gitHubConfig.clientId)&scope=user:email")!

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: gitHubConfig.callbackURLScheme
            ) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: GitHubAuthError.cancelled)
                    return
                }

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GitHubAuthError.invalidCallback)
                    return
                }

                continuation.resume(returning: code)
            }

            session.presentationContextProvider = PresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false

            if !session.start() {
                continuation.resume(throwing: GitHubAuthError.sessionStartFailed)
            }
        }
    }
}

// MARK: - GitHub Auth Errors

enum GitHubAuthError: Error, LocalizedError, Equatable {
    case cancelled
    case invalidCallback
    case sessionStartFailed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "GitHub authentication was cancelled."
        case .invalidCallback:
            return "Invalid callback from GitHub."
        case .sessionStartFailed:
            return "Failed to start authentication session."
        }
    }
}

// MARK: - Presentation Context Provider

@MainActor
private class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return UIWindow()
        }
        return windowScene.windows.first ?? UIWindow()
    }
}
