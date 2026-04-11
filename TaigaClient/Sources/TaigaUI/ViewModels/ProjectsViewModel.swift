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

public struct ActivityItem: Identifiable, Equatable {
    public enum Kind: String, Equatable {
        case story = "Story"
        case task = "Task"
        case issue = "Issue"
    }

    public enum Scope: String, Equatable {
        case assigned = "Assigned"
        case memberProject = "Project"
    }

    public let itemId: Int
    public let projectId: Int
    public let projectName: String
    public let subject: String
    public let kind: Kind
    public let scope: Scope
    public let timestamp: Date?

    public var id: String {
        "\(scope.rawValue)-\(kind.rawValue)-\(itemId)-\(projectId)"
    }

    public var dedupeKey: String {
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
            activity: [ActivityItem],
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
            let currentUser = try? await projectsService.currentUser(using: token)
            guard let userId = token.userId ?? currentUser?.id else {
                throw TaigaError.invalidCredentials
            }

            let relatedProjects = (try? await projectsService.relatedProjects(memberId: userId, using: token)) ?? []
            let relatedProjectIds = Set(relatedProjects.map(\.id))

            state = .loaded(
                projects: relatedProjects,
                myWork: [],
                activity: [],
                username: currentUser?.username,
                relatedProjectIds: Array(relatedProjectIds)
            )
            lastUpdated = Date()

            await loadMyWork(
                token: token,
                currentUserId: userId,
                username: currentUser?.username,
                projects: relatedProjects,
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
        var projectNames = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })

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

        async let relatedStoriesTask: [UserStory] = fetchStories(for: Array(baseRelatedProjectIds), token: token)
        async let relatedTasksTask: [Task] = fetchTasks(for: Array(baseRelatedProjectIds), token: token)
        async let relatedIssuesTask: [Issue] = fetchIssues(for: Array(baseRelatedProjectIds), token: token)

        let relatedStories = await relatedStoriesTask
        let relatedTasks = await relatedTasksTask
        let relatedIssues = await relatedIssuesTask

        let assignedActivityStories = assignedStories.compactMap { story -> ActivityItem? in
            guard let projectId = story.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: story.id,
                projectId: projectId,
                projectName: projectName,
                subject: story.subject,
                kind: .story,
                scope: .assigned,
                timestamp: story.modifiedDate ?? story.createdDate
            )
        }

        let assignedActivityTasks = assignedTasks.compactMap { task -> ActivityItem? in
            guard let projectId = task.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: task.id,
                projectId: projectId,
                projectName: projectName,
                subject: task.subject,
                kind: .task,
                scope: .assigned,
                timestamp: task.modifiedDate ?? task.createdDate
            )
        }

        let assignedActivityIssues = assignedIssues.compactMap { issue -> ActivityItem? in
            guard let projectId = issue.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: issue.id,
                projectId: projectId,
                projectName: projectName,
                subject: issue.subject,
                kind: .issue,
                scope: .assigned,
                timestamp: issue.modifiedDate ?? issue.createdDate
            )
        }

        let memberActivityStories = relatedStories.compactMap { story -> ActivityItem? in
            guard let projectId = story.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: story.id,
                projectId: projectId,
                projectName: projectName,
                subject: story.subject,
                kind: .story,
                scope: .memberProject,
                timestamp: story.modifiedDate ?? story.createdDate
            )
        }

        let memberActivityTasks = relatedTasks.compactMap { task -> ActivityItem? in
            guard let projectId = task.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: task.id,
                projectId: projectId,
                projectName: projectName,
                subject: task.subject,
                kind: .task,
                scope: .memberProject,
                timestamp: task.modifiedDate ?? task.createdDate
            )
        }

        let memberActivityIssues = relatedIssues.compactMap { issue -> ActivityItem? in
            guard let projectId = issue.project,
                  let projectName = projectNames[projectId] else {
                return nil
            }
            return ActivityItem(
                itemId: issue.id,
                projectId: projectId,
                projectName: projectName,
                subject: issue.subject,
                kind: .issue,
                scope: .memberProject,
                timestamp: issue.modifiedDate ?? issue.createdDate
            )
        }

        let combined = assignedActivityStories
            + assignedActivityTasks
            + assignedActivityIssues
            + memberActivityStories
            + memberActivityTasks
            + memberActivityIssues

        var uniqueByKey: [String: ActivityItem] = [:]
        for item in combined {
            if let existing = uniqueByKey[item.dedupeKey] {
                if existing.scope == .memberProject && item.scope == .assigned {
                    uniqueByKey[item.dedupeKey] = item
                } else if (item.timestamp ?? .distantPast) > (existing.timestamp ?? .distantPast) {
                    uniqueByKey[item.dedupeKey] = item
                }
            } else {
                uniqueByKey[item.dedupeKey] = item
            }
        }

        let activity = uniqueByKey.values.sorted {
            ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast)
        }

        var relatedProjectIds = baseRelatedProjectIds
        relatedProjectIds.formUnion(myWork.map(\.projectId))
        relatedProjectIds.formUnion(activity.map(\.projectId))

        // Check notification preferences and send if needed
        let notifyAssigned = UserDefaults.standard.bool(forKey: "notify-assigned-items") || !UserDefaults.standard.bool(forKey: "notify-assigned-items-set")
        let notifyNew = UserDefaults.standard.bool(forKey: "notify-new-items") || !UserDefaults.standard.bool(forKey: "notify-new-items-set")
        
        if notifyAssigned || notifyNew {
            await checkAndNotifyNewItems(
                myWork: myWork,
                activity: activity,
                notifyAssigned: notifyAssigned,
                notifyNew: notifyNew
            )
        }

        state = .loaded(
            projects: projects,
            myWork: myWork,
            activity: activity,
            username: username,
            relatedProjectIds: Array(relatedProjectIds)
        )
        lastUpdated = Date()
    }

    private func fetchStories(for projectIds: [Int], token: AuthToken) async -> [UserStory] {
        await withTaskGroup(of: [UserStory].self) { group in
            for projectId in projectIds {
                group.addTask { [projectsService] in
                    (try? await projectsService.userStories(projectId: projectId, using: token)) ?? []
                }
            }

            var all: [UserStory] = []
            for await result in group {
                all.append(contentsOf: result)
            }
            return all
        }
    }

    private func fetchTasks(for projectIds: [Int], token: AuthToken) async -> [Task] {
        await withTaskGroup(of: [Task].self) { group in
            for projectId in projectIds {
                group.addTask { [projectsService] in
                    (try? await projectsService.tasks(projectId: projectId, using: token)) ?? []
                }
            }

            var all: [Task] = []
            for await result in group {
                all.append(contentsOf: result)
            }
            return all
        }
    }

    private func fetchIssues(for projectIds: [Int], token: AuthToken) async -> [Issue] {
        await withTaskGroup(of: [Issue].self) { group in
            for projectId in projectIds {
                group.addTask { [projectsService] in
                    (try? await projectsService.issues(projectId: projectId, using: token)) ?? []
                }
            }

            var all: [Issue] = []
            for await result in group {
                all.append(contentsOf: result)
            }
            return all
        }
    }

    private func checkAndNotifyNewItems(
        myWork: [MyWorkItem],
        activity: [ActivityItem],
        notifyAssigned: Bool,
        notifyNew: Bool
    ) async {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Get previously seen myWork items
        let prevMyWorkData = UserDefaults.standard.data(forKey: "previous-mywork-items")
        let previousMyWorkIds = prevMyWorkData.flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let previousMyWorkSet = Set(previousMyWorkIds)
        let currentMyWorkIds = myWork.map(\.id)
        let currentMyWorkSet = Set(currentMyWorkIds)

        // Get previously seen activity items (assigned items only)
        let prevAssignedData = UserDefaults.standard.data(forKey: "previous-assigned-items")
        let previousAssignedIds = prevAssignedData.flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let previousAssignedSet = Set(previousAssignedIds)

        let assignedItems = activity.filter { $0.scope == .assigned }
        let currentAssignedIds = assignedItems.map(\.id)
        let currentAssignedSet = Set(currentAssignedIds)

        // Notify about newly assigned items
        if notifyAssigned {
            let newAssignedIds = currentAssignedSet.subtracting(previousAssignedSet)
            for item in assignedItems where newAssignedIds.contains(item.id) {
                await NotificationManager.shared.scheduleNotification(
                    title: "New Assignment",
                    subtitle: item.projectName,
                    body: item.subject,
                    userInfo: ["itemId": item.itemId, "projectId": item.projectId]
                )
            }
        }

        // Notify about new items in member projects
        if notifyNew {
            let memberProjectItems = activity.filter { $0.scope == .memberProject }
            let newMemberItemIds = Set(memberProjectItems.map(\.id)).subtracting(previousAssignedSet)
            
            for item in memberProjectItems where newMemberItemIds.contains(item.id) {
                await NotificationManager.shared.scheduleNotification(
                    title: "New \(item.kind.rawValue)",
                    subtitle: item.projectName,
                    body: item.subject,
                    userInfo: ["itemId": item.itemId, "projectId": item.projectId]
                )
            }
        }

        // Store current items for next comparison
        if let encoded = try? encoder.encode(currentMyWorkIds) {
            UserDefaults.standard.set(encoded, forKey: "previous-mywork-items")
        }
        if let encoded = try? encoder.encode(currentAssignedIds) {
            UserDefaults.standard.set(encoded, forKey: "previous-assigned-items")
        }
    }
}

