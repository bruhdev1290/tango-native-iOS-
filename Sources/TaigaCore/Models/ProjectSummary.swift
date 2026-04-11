import Foundation

public struct ProjectSummary: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let name: String
    public let slug: String
    public let description: String?
    public let logoSmallURL: String?
    public let logoBigURL: String?
    public let isPrivate: Bool?
    public let isEpicsActivated: Bool?
    public let isBacklogActivated: Bool?
    public let isKanbanActivated: Bool?
    public let isIssuesActivated: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description
        case logoSmallURL = "logo_small_url"
        case logoBigURL = "logo_big_url"
        case logoSmall = "logo_small"
        case logoBig = "logo_big"
        case logo = "logo"
        case isPrivate = "is_private"
        case isEpicsActivated = "is_epics_activated"
        case isBacklogActivated = "is_backlog_activated"
        case isKanbanActivated = "is_kanban_activated"
        case isIssuesActivated = "is_issues_activated"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate)
        isEpicsActivated = try container.decodeIfPresent(Bool.self, forKey: .isEpicsActivated)
        isBacklogActivated = try container.decodeIfPresent(Bool.self, forKey: .isBacklogActivated)
        isKanbanActivated = try container.decodeIfPresent(Bool.self, forKey: .isKanbanActivated)
        isIssuesActivated = try container.decodeIfPresent(Bool.self, forKey: .isIssuesActivated)

        logoSmallURL = try container.decodeIfPresent(String.self, forKey: .logoSmallURL)
            ?? container.decodeIfPresent(String.self, forKey: .logoSmall)
            ?? container.decodeIfPresent(String.self, forKey: .logo)

        logoBigURL = try container.decodeIfPresent(String.self, forKey: .logoBigURL)
            ?? container.decodeIfPresent(String.self, forKey: .logoBig)
            ?? container.decodeIfPresent(String.self, forKey: .logo)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(slug, forKey: .slug)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(logoSmallURL, forKey: .logoSmallURL)
        try container.encodeIfPresent(logoBigURL, forKey: .logoBigURL)
        try container.encodeIfPresent(isPrivate, forKey: .isPrivate)
        try container.encodeIfPresent(isEpicsActivated, forKey: .isEpicsActivated)
        try container.encodeIfPresent(isBacklogActivated, forKey: .isBacklogActivated)
        try container.encodeIfPresent(isKanbanActivated, forKey: .isKanbanActivated)
        try container.encodeIfPresent(isIssuesActivated, forKey: .isIssuesActivated)
    }
}
