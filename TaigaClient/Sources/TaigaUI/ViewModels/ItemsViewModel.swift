import Foundation
import Observation
import TaigaCore

@Observable
public final class ItemsViewModel {
    public struct MentionCandidate: Identifiable, Equatable, Sendable {
        public let userId: Int
        public let username: String?
        public let fullName: String?
        public let avatarURL: String?

        public var id: Int { userId }

        public var displayName: String {
            if let fullName, !fullName.isEmpty {
                return fullName
            }
            if let username, !username.isEmpty {
                return username
            }
            return "User #\(userId)"
        }

        public var handle: String {
            if let username, !username.isEmpty {
                return "@\(username)"
            }
            return "@\(userId)"
        }

        public var mentionValue: String {
            handle
        }
    }

    public enum State: Equatable {
        case idle
        case loading
        case loaded(stories: [UserStory], tasks: [Task], issues: [Issue], sprints: [Sprint])
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public private(set) var lastUpdated: Date?
    @MainActor public private(set) var mentionCandidates: [MentionCandidate] = []

    private let itemsService: ItemsService
    private let authService: AuthService
    private let projectId: Int

    private struct MentionResolutionError: LocalizedError {
        let text: String
        var errorDescription: String? { text }
    }

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
            async let issues = itemsService.issues(projectId: projectId, token: token)
            async let sprints = itemsService.sprints(projectId: projectId, token: token)
            async let memberships = itemsService.memberships(projectId: projectId, token: token)
            async let currentUser = itemsService.currentUser(token: token)
            let result = try await (stories, tasks, issues, sprints, memberships, currentUser)
            state = .loaded(stories: result.0, tasks: result.1, issues: result.2, sprints: result.3)
            mentionCandidates = buildMentionCandidates(memberships: result.4, currentUser: result.5)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @MainActor
    public func mentionSuggestions(for text: String) -> [MentionCandidate] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("@") else { return [] }
        let query = String(trimmed.dropFirst()).lowercased()

        if query.isEmpty {
            return Array(mentionCandidates.prefix(8))
        }

        return mentionCandidates.filter { candidate in
            candidate.displayName.lowercased().contains(query)
                || (candidate.username?.lowercased().contains(query) ?? false)
                || "\(candidate.userId)".contains(query)
        }
        .prefix(8)
        .map { $0 }
    }

    @MainActor
    public func createStory(
        subject: String,
        description: String?,
        tags: [String],
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?,
        attachments: [AttachmentUpload]
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let normalizedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token)
        _ = try await itemsService.createUserStory(
            projectId: projectId,
            subject: normalized,
            description: normalizedDescription,
            tags: tags,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            points: points,
            attachments: attachments,
            token: token
        )
        await load()
    }

    @MainActor
    public func createTask(
        subject: String,
        userStoryId: Int?,
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token)
        _ = try await itemsService.createTask(
            projectId: projectId,
            subject: normalized,
            userStoryId: userStoryId,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
        await load()
    }

    @MainActor
    public func updateStory(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token) ?? assignedTo
        _ = try await itemsService.updateUserStory(
            id: id,
            subject: normalized,
            status: status,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            points: points,
            token: token
        )
        await load()
    }

    @MainActor
    public func updateTask(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token) ?? assignedTo
        _ = try await itemsService.updateTask(
            id: id,
            subject: normalized,
            status: status,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
        await load()
    }

    @MainActor
    public func createIssue(
        subject: String,
        description: String?,
        tags: [String],
        severity: Int?,
        priority: Int?,
        issueType: Int?,
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        attachments: [AttachmentUpload]
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let normalizedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token)
        _ = try await itemsService.createIssue(
            projectId: projectId,
            subject: normalized,
            description: normalizedDescription,
            tags: tags,
            severity: severity,
            priority: priority,
            issueType: issueType,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            attachments: attachments,
            token: token
        )
        await load()
    }

    @MainActor
    public func updateIssue(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        assigneeMention: String?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?
    ) async throws {
        let normalized = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let token = try await authService.authenticatedToken()
        let resolvedAssignee = try await resolveAssigneeId(from: assigneeMention, token: token) ?? assignedTo
        _ = try await itemsService.updateIssue(
            id: id,
            subject: normalized,
            status: status,
            assignedTo: resolvedAssignee,
            dueDate: dueDate,
            dueDateReason: dueDateReason,
            isBlocked: isBlocked,
            blockedNote: blockedNote,
            token: token
        )
        await load()
    }

    @MainActor
    public func deleteStory(id: Int) async throws {
        let token = try await authService.authenticatedToken()
        try await itemsService.deleteUserStory(id: id, token: token)
        await load()
    }

    @MainActor
    public func deleteTask(id: Int) async throws {
        let token = try await authService.authenticatedToken()
        try await itemsService.deleteTask(id: id, token: token)
        await load()
    }

    @MainActor
    public func deleteIssue(id: Int) async throws {
        let token = try await authService.authenticatedToken()
        try await itemsService.deleteIssue(id: id, token: token)
        await load()
    }

    @MainActor
    private func resolveAssigneeId(from mention: String?, token: AuthToken) async throws -> Int? {
        guard let mention else { return nil }
        let value = mention.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        let key = value.hasPrefix("@") ? String(value.dropFirst()) : value
        guard !key.isEmpty else { return nil }

        if key.caseInsensitiveCompare("me") == .orderedSame {
            let user = try await itemsService.currentUser(token: token)
            return user.id
        }

        if let id = Int(key) {
            return id
        }

        if let localMatch = mentionCandidates.first(where: {
            ($0.username?.caseInsensitiveCompare(key) == .orderedSame)
                || ($0.fullName?.caseInsensitiveCompare(key) == .orderedSame)
        }) {
            return localMatch.userId
        }

        let memberships = try await itemsService.memberships(projectId: projectId, token: token)
        if let byUsername = memberships.first(where: { $0.username?.caseInsensitiveCompare(key) == .orderedSame })?.user {
            return byUsername
        }

        if let byFullName = memberships.first(where: { $0.fullName?.caseInsensitiveCompare(key) == .orderedSame })?.user {
            return byFullName
        }

        throw MentionResolutionError(text: "Could not resolve assignee mention @\(key). Try @me, @username, or @123.")
    }

    private func buildMentionCandidates(memberships: [Membership], currentUser: CurrentUser) -> [MentionCandidate] {
        var seen = Set<Int>()
        var list: [MentionCandidate] = []

        list.append(
            MentionCandidate(
                userId: currentUser.id,
                username: currentUser.username,
                fullName: currentUser.fullName,
                avatarURL: nil
            )
        )
        seen.insert(currentUser.id)

        for membership in memberships {
            guard let userId = membership.user, !seen.contains(userId) else { continue }
            list.append(
                MentionCandidate(
                    userId: userId,
                    username: membership.username,
                    fullName: membership.fullName,
                    avatarURL: membership.avatarURL
                )
            )
            seen.insert(userId)
        }

        return list.sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
}
