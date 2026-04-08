import Foundation

public struct ProjectSummary: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String
    public let description: String?
    public let isPrivate: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case isPrivate = "is_private"
    }
}
