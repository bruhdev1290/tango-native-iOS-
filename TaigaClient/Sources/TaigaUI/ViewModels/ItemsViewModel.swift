import Foundation
import Observation
import TaigaCore

@Observable
public final class ItemsViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(stories: [UserStory], tasks: [Task], sprints: [Sprint])
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public private(set) var lastUpdated: Date?

    private let itemsService: ItemsService
    private let authService: AuthService
    private let projectId: Int

    public init(itemsService: ItemsService, authService: AuthService, projectId: Int) {
        self.itemsService = itemsService
        self.authService = authService
        self.projectId = projectId
    }

    @MainActor
    public func load() async {
        state = .loading
        do {
            let token = try await authService.authenticatedToken()
            async let stories = itemsService.userStories(projectId: projectId, token: token)
            async let tasks = itemsService.tasks(projectId: projectId, token: token)
            async let sprints = itemsService.sprints(projectId: projectId, token: token)
            let result = try await (stories, tasks, sprints)
            state = .loaded(stories: result.0, tasks: result.1, sprints: result.2)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    public func createStory(subject: String) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        _ = try await itemsService.createUserStory(projectId: projectId, subject: normalized, token: token)
        await load()
    }

    @MainActor
    public func createTask(subject: String, userStoryId: Int?) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        _ = try await itemsService.createTask(projectId: projectId, subject: normalized, userStoryId: userStoryId, token: token)
        await load()
    }

    @MainActor
    public func updateStory(id: Int, subject: String, status: Int?, assignedTo: Int?) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        _ = try await itemsService.updateUserStory(id: id, subject: normalized, status: status, assignedTo: assignedTo, token: token)
        await load()
    }

    @MainActor
    public func updateTask(id: Int, subject: String, status: Int?, assignedTo: Int?) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        _ = try await itemsService.updateTask(id: id, subject: normalized, status: status, assignedTo: assignedTo, token: token)
        await load()
    }
}
