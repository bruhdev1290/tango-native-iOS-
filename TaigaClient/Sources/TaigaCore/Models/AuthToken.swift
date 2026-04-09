import Foundation

public struct AuthToken: Codable, Sendable, Equatable {
    public let authToken: String
    public let tokenType: String?
    public let expires: Date?
    public let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
        case tokenType = "token_type"
        case expires = "expires"
        case refreshToken = "refresh_token"
    }
}
