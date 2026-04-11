import Foundation

public struct Membership: Codable, Identifiable, Sendable, Equatable {
    public let id: Int
    public let user: Int?
    public let projectId: Int?
    public let username: String?
    public let fullName: String?
    public let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, user, project
        case userExtraInfo = "user_extra_info"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        let userReference = try? container.decode(UserReference.self, forKey: .user)
        let userExtraInfo = try? container.decode(UserExtraInfo.self, forKey: .userExtraInfo)

        if let userId = try? container.decode(Int.self, forKey: .user) {
            user = userId
        } else {
            user = userReference?.id ?? userExtraInfo?.id
        }

        username = userReference?.username ?? userExtraInfo?.username
        fullName = userReference?.fullName ?? userExtraInfo?.fullName
        avatarURL = userReference?.avatarURL ?? userExtraInfo?.photo ?? userExtraInfo?.bigPhoto

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
        try container.encodeIfPresent(
            username.map { UserExtraInfo(id: user, username: $0, fullName: fullName, photo: avatarURL, bigPhoto: nil) },
            forKey: .userExtraInfo
        )
    }
}

private struct ProjectReference: Codable, Sendable, Equatable {
    let id: Int
}

private struct UserReference: Codable, Sendable, Equatable {
    let id: Int
    let username: String?
    let fullName: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
        case avatarURL = "photo"
    }
}

private struct UserExtraInfo: Codable, Sendable, Equatable {
    let id: Int?
    let username: String?
    let fullName: String?
    let photo: String?
    let bigPhoto: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
        case photo
        case bigPhoto = "big_photo"
    }
}