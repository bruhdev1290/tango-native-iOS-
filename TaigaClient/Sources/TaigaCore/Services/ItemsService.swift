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

    public func createUserStory(projectId: Int, subject: String, token: AuthToken) async throws -> UserStory {
        try await api.createUserStory(projectId: projectId, subject: subject, token: token)
    }

    public func updateUserStory(id: Int, subject: String, status: Int?, assignedTo: Int?, token: AuthToken) async throws -> UserStory {
        try await api.updateUserStory(id: id, subject: subject, status: status, assignedTo: assignedTo, token: token)
    }

    public func createTask(projectId: Int, subject: String, userStoryId: Int?, token: AuthToken) async throws -> Task {
        try await api.createTask(projectId: projectId, subject: subject, userStoryId: userStoryId, token: token)
    }

    public func updateTask(id: Int, subject: String, status: Int?, assignedTo: Int?, token: AuthToken) async throws -> Task {
        try await api.updateTask(id: id, subject: subject, status: status, assignedTo: assignedTo, token: token)
    }
}
