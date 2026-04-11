import Foundation

public actor AuthService {
    private let api: TaigaAPIClient
    private var token: AuthToken?
    private let keychain: KeychainStore

    public init(api: TaigaAPIClient = TaigaAPIClient(), keychain: KeychainStore = KeychainStore()) {
        self.api = api
        self.keychain = keychain
        if let data = keychain.data(for: tokenKey),
           let saved = try? JSONDecoder().decode(AuthToken.self, from: data) {
            self.token = saved
        }
    }

    private var tokenKey: String {
        "taiga-auth-token-\(api.baseURL.absoluteString)"
    }

    public func currentToken() -> AuthToken? {
        token
    }

    /// Returns a fresh token, refreshing if we have a refresh_token and the current one is expired/near expiry.
    public func authenticatedToken(leeway: TimeInterval = 300) async throws -> AuthToken {
        if let token, let expires = token.expires, expires.timeIntervalSinceNow < leeway {
            try await refresh()
        }
        if let token {
            return token
        }
        throw TaigaError.invalidCredentials
    }

    @discardableResult
    public func login(username: String, password: String) async throws -> AuthToken {
        let token = try await api.login(username: username, password: password)
        self.token = token
        if let data = try? JSONEncoder().encode(token) {
            try? keychain.set(data, for: tokenKey)
        }
        return token
    }

    @discardableResult
    public func loginWithGitHub(code: String) async throws -> AuthToken {
        let token = try await api.loginWithGitHub(code: code)
        self.token = token
        if let data = try? JSONEncoder().encode(token) {
            try? keychain.set(data, for: tokenKey)
        }
        return token
    }

    public func logout() {
        token = nil
        keychain.remove(tokenKey)
    }

    // MARK: - Refresh

    public func refresh() async throws {
        guard let refreshToken = token?.refreshToken else {
            throw TaigaError.invalidCredentials
        }
        let newToken = try await api.refresh(refreshToken: refreshToken)
        token = newToken
        if let data = try? JSONEncoder().encode(newToken) {
            try? keychain.set(data, for: tokenKey)
        }
    }
}
