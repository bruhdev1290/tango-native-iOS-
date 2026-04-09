import Foundation
import Observation
import TaigaCore

public struct MyWorkItem: Identifiable, Equatable {
    public enum Kind: String, Equatable {
        case story = "Story"
        case task = "Task"
        case issue = "Issue"
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
        case loaded(
            projects: [ProjectSummary],
            myWork: [MyWorkItem],
            username: String?,
            relatedProjectIds: [Int]
        )
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public private(set) var lastUpdated: Date?

    private let projectsService: ProjectsService
    private let authService: AuthService

    public init(projectsService: ProjectsService, authService: AuthService) {
        self.projectsService = projectsService
        self.authService = authService
    }

    @MainActor
    public func load() async {
        state = .loading
        do {
            let token = try await authService.authenticatedToken()
            async let projectsTask = projectsService.listProjects(using: token)
            async let currentUserTask = projectsService.currentUser(using: token)

            let projects = try await projectsTask
            let currentUser = try? await currentUserTask
            guard let userId = token.userId ?? currentUser?.id else {
                throw TaigaError.invalidCredentials
            }

            let relatedProjects = (try? await projectsService.relatedProjects(memberId: userId, using: token)) ?? []
            let allProjects = mergedProjects(primary: relatedProjects, secondary: projects)
            let relatedProjectIds = Set(relatedProjects.map(\.id))

            state = .loaded(
                projects: allProjects,
                myWork: [],
                username: currentUser?.username,
                relatedProjectIds: Array(relatedProjectIds)
            )
            lastUpdated = Date()

            await loadMyWork(
                token: token,
                currentUserId: userId,
                username: currentUser?.username,
                projects: allProjects,
                baseRelatedProjectIds: relatedProjectIds
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    private func loadMyWork(
        token: AuthToken,
        currentUserId: Int,
        username: String?,
        projects: [ProjectSummary],
        baseRelatedProjectIds: Set<Int>
    ) async {
        let projectNames = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })

        async let assignedStoriesTask = projectsService.assignedUserStories(assigneeId: currentUserId, using: token)
        async let assignedTasksTask = projectsService.assignedTasks(assigneeId: currentUserId, using: token)
        async let assignedIssuesTask = projectsService.assignedIssues(assigneeId: currentUserId, using: token)

        let assignedStories = (try? await assignedStoriesTask) ?? []
        let assignedTasks = (try? await assignedTasksTask) ?? []
        let assignedIssues = (try? await assignedIssuesTask) ?? []

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

        let issueItems = assignedIssues.compactMap { issue -> MyWorkItem? in
            guard let projectId = issue.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }

            return MyWorkItem(
                itemId: issue.id,
                projectId: projectId,
                projectName: projectName,
                subject: issue.subject,
                kind: .issue
            )
        }

        let myWork = storyItems + taskItems + issueItems
        var relatedProjectIds = baseRelatedProjectIds
        relatedProjectIds.formUnion(myWork.map(\.projectId))

        state = .loaded(
            projects: projects,
            myWork: myWork,
            username: username,
            relatedProjectIds: Array(relatedProjectIds)
        )
        lastUpdated = Date()
    }

    private func mergedProjects(primary: [ProjectSummary], secondary: [ProjectSummary]) -> [ProjectSummary] {
        var seen = Set<Int>()
        var merged: [ProjectSummary] = []

        for project in primary + secondary where !seen.contains(project.id) {
            seen.insert(project.id)
            merged.append(project)
        }

        return merged
    }
}
