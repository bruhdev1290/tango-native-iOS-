import Foundation

public struct Task: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let project: Int?
    public let userStory: Int?
    public let subject: String
    public let status: Int?
    public let createdDate: Date?
    public let modifiedDate: Date?
    public let assignedTo: Int?
    public let dueDate: String?
    public let dueDateReason: String?
    public let isBlocked: Bool?
    public let blockedNote: String?

    enum CodingKeys: String, CodingKey {
        case id, project, subject, status
        case userStory = "user_story"
        case createdDate = "created_date"
        case modifiedDate = "modified_date"
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case dueDateReason = "due_date_reason"
        case isBlocked = "is_blocked"
        case blockedNote = "blocked_note"
    }
}
