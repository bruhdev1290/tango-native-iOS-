import Foundation

public struct UserStory: Codable, Identifiable, Sendable {
    public let id: Int
    public let project: Int?
    public let subject: String
    public let status: Int?
    public let assignedTo: Int?
    public let points: [String: Int]? // mapping by role

    enum CodingKeys: String, CodingKey {
        case id, project, subject, status, points
        case assignedTo = "assigned_to"
    }
}
