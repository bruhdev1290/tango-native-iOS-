import Foundation

public struct CurrentUser: Codable, Sendable, Equatable {
    public let id: Int
    public let username: String?
    public let fullName: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
    }
}