import Foundation

public struct Issue: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let project: Int?
    public let subject: String
    public let status: Int?
    public let assignedTo: Int?
    public let dueDate: String?
    public let dueDateReason: String?
    public let isBlocked: Bool?
    public let blockedNote: String?

    enum CodingKeys: String, CodingKey {
        case id, project, subject, status
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case dueDateReason = "due_date_reason"
        case isBlocked = "is_blocked"
        case blockedNote = "blocked_note"
    }
}