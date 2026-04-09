import Foundation

public struct Membership: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let user: Int?
    public let projectId: Int?

    enum CodingKeys: String, CodingKey {
        case id, user, project
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        user = try? container.decode(Int.self, forKey: .user)

        if let projectInt = try? container.decode(Int.self, forKey: .project) {
            projectId = projectInt
        } else if let projectObject = try? container.decode(ProjectReference.self, forKey: .project) {
            projectId = projectObject.id
        } else {
            projectId = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(projectId, forKey: .project)
    }
}

private struct ProjectReference: Codable, Sendable, Equatable {
    let id: Int
}