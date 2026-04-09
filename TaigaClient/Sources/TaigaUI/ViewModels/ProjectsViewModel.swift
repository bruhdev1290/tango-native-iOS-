import Foundation
import Observation
import TaigaCore

public struct MyWorkItem: Identifiable, Equatable {
    public enum Kind: String, Equatable {
        case story = "Story"
        case task = "Task"
    }

    public let itemId: Int
    public let projectId: Int
    public let projectName: String
    public let subject: String
    public let kind: Kind

    public var id: String {
        "\(kind.rawValue)-\(itemId)"
    }
}

@Observable
public final class ProjectsViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(projects: [ProjectSummary], myWork: [MyWorkItem], username: String?)
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public private(set) var lastUpdated: Date?

    private let projectsService: ProjectsService
    private let authService: AuthService
    private let itemsService: ItemsService

    public init(projectsService: ProjectsService, authService: AuthService, itemsService: ItemsService) {
        self.projectsService = projectsService
        self.authService = authService
        self.itemsService = itemsService
    }

    @MainActor
    public func load() async {
        state = .loading
        do {
            let token = try await authService.authenticatedToken()
            async let projectsTask = projectsService.listProjects(using: token)
            async let currentUserTask = projectsService.currentUser(using: token)

            let projects = try await projectsTask
            let currentUser = try await currentUserTask
            let projectNames = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })

            async let assignedStoriesTask = projectsService.assignedUserStories(assigneeId: currentUser.id, using: token)
            async let assignedTasksTask = projectsService.assignedTasks(assigneeId: currentUser.id, using: token)

            let assignedStories = try await assignedStoriesTask
            let assignedTasks = try await assignedTasksTask

            let storyItems = assignedStories.compactMap { story -> MyWorkItem? in
                guard let projectId = story.project,
                      let projectName = projectNames[projectId] else {
                    return nil
                }

                return MyWorkItem(
                    itemId: story.id,
                    projectId: projectId,
                    projectName: projectName,
                    subject: story.subject,
                    kind: .story
                )
            }

            let taskItems = assignedTasks.compactMap { task -> MyWorkItem? in
                guard let projectId = task.project,
                      let projectName = projectNames[projectId] else {
                    return nil
                }

                return MyWorkItem(
                    itemId: task.id,
                    projectId: projectId,
                    projectName: projectName,
                    subject: task.subject,
                    kind: .task
                )
            }

            let myWork = storyItems + taskItems
            state = .loaded(projects: projects, myWork: myWork, username: currentUser.username)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
