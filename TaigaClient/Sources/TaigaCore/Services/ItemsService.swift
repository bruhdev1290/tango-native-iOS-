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

    public func sprints(projectId: Int, token: AuthToken) async throws -> [Sprint] {
        try await api.fetchSprints(projectId: projectId, token: token)
    }
}
