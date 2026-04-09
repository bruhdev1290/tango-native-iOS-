import Foundation

public actor ProjectsService {
    private let api: TaigaAPIClient

    public init(api: TaigaAPIClient = TaigaAPIClient()) {
        self.api = api
    }

    public func listProjects(using token: AuthToken) async throws -> [ProjectSummary] {
        try await api.fetchProjects(token: token)
    }

    public func currentUser(using token: AuthToken) async throws -> CurrentUser {
        try await api.fetchCurrentUser(token: token)
    }

    public func assignedUserStories(assigneeId: Int, using token: AuthToken) async throws -> [UserStory] {
        try await api.fetchAssignedUserStories(assigneeId: assigneeId, token: token)
    }

    public func assignedTasks(assigneeId: Int, using token: AuthToken) async throws -> [Task] {
        try await api.fetchAssignedTasks(assigneeId: assigneeId, token: token)
    }
}
