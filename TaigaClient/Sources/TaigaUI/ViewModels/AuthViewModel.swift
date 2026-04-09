import Foundation
import Observation
import TaigaCore

@Observable
public final class AuthViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case authenticated(AuthToken)
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle

    private let authService: AuthService

    public init(authService: AuthService) {
        self.authService = authService
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
}
