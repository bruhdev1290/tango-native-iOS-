import Foundation

public actor ItemsService {
    private let api: TaigaAPIClient

    public init(api: TaigaAPIClient = TaigaAPIClient()) {
        self.api = api
    }

    public func userStories(projectId: Int, token: AuthToken) async throws -> [UserStory] {
        try await api.fetchUserStories(projectId: projectId, token: token)
    }

    public func tasks(projectId: Int, token: AuthToken) async throws -> [Task] {
        try await api.fetchTasks(projectId: projectId, token: token)
    }

    public func issues(projectId: Int, token: AuthToken) async throws -> [Issue] {
        try await api.fetchIssues(projectId: projectId, token: token)
    }

    public func sprints(projectId: Int, token: AuthToken) async throws -> [Sprint] {
        try await api.fetchSprints(projectId: projectId, token: token)
    }

    public func currentUser(token: AuthToken) async throws -> CurrentUser {
        try await api.fetchCurrentUser(token: token)
    }

    public func memberships(projectId: Int, token: AuthToken) async throws -> [Membership] {
        try await api.fetchMemberships(projectId: projectId, token: token)
    }

    public func createUserStory(
        projectId: Int,
        subject: String,
        description: String?,
        tags: [String],
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?,
        attachments: [AttachmentUpload],
        token: AuthToken
    ) async throws -> UserStory {
        try await api.createUserStory(
            projectId: projectId,
            subject: subject,
            description: description,
            tags: tags,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            points: points,
            attachments: attachments,
            token: token
        )
    }

    public func updateUserStory(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?,
        token: AuthToken
    ) async throws -> UserStory {
        try await api.updateUserStory(
            id: id,
            subject: subject,
            status: status,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            points: points,
            token: token
        )
    }

    public func createTask(
        projectId: Int,
        subject: String,
        userStoryId: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Task {
        try await api.createTask(
            projectId: projectId,
            subject: subject,
            userStoryId: userStoryId,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
    }

    public func createIssue(
        projectId: Int,
        subject: String,
        description: String?,
        tags: [String],
        severity: Int?,
        priority: Int?,
        issueType: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        attachments: [AttachmentUpload],
        token: AuthToken
    ) async throws -> Issue {
        try await api.createIssue(
            projectId: projectId,
            subject: subject,
            description: description,
            tags: tags,
            severity: severity,
            priority: priority,
            issueType: issueType,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            attachments: attachments,
            token: token
        )
    }

    public func updateTask(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Task {
        try await api.updateTask(
            id: id,
            subject: subject,
            status: status,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
    }

    public func updateIssue(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Issue {
        try await api.updateIssue(
            id: id,
            subject: subject,
            status: status,
            assignedTo: assignedTo,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
    }
}
