import Foundation

/// Configuration for GitHub OAuth authentication
public struct GitHubOAuthConfig: Sendable {
    /// GitHub OAuth App Client ID
    public let clientId: String
    
    /// URL scheme for the callback (e.g., "taiga")
    public let callbackURLScheme: String
    
    /// Whether GitHub authentication is enabled
    public var isEnabled: Bool { !clientId.isEmpty }
    
    public init(clientId: String = "", callbackURLScheme: String = "taiga") {
        self.clientId = clientId
        self.callbackURLScheme = callbackURLScheme
    }
    
    /// Default configuration - GitHub auth disabled
    public static let `default` = GitHubOAuthConfig()
}
