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
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
