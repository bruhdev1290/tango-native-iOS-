import Foundation

public struct Task: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let project: Int?
    public let userStory: Int?
    public let subject: String
    public let status: Int?
    public let assignedTo: Int?

    enum CodingKeys: String, CodingKey {
        case id, project, subject, status
        case userStory = "user_story"
        case assignedTo = "assigned_to"
    }
}
