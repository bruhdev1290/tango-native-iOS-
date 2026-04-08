import Foundation

public struct Sprint: Codable, Identifiable, Sendable {
    public let id: Int
    public let project: Int?
    public let name: String
    public let slug: String?
    public let estimatedStart: String?
    public let estimatedFinish: String?

    enum CodingKeys: String, CodingKey {
        case id, project, name, slug
        case estimatedStart = "estimated_start"
        case estimatedFinish = "estimated_finish"
    }
}
