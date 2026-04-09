import SwiftUI
import TaigaCore

public struct ProjectDetailView: View {
    private enum DisplayFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case sprints = "Sprints"
        case stories = "Stories"
        case tasks = "Tasks"

        var id: String { rawValue }
    }

    @Bindable private var viewModel: ItemsViewModel
    @State private var searchText: String = ""
    @State private var displayFilter: DisplayFilter = .all
    @State private var statusFilter: Int?
    @State private var assigneeFilter: Int?
    @State private var activeSheet: ItemSheet?

    public init(viewModel: ItemsViewModel) {
        self.viewModel = viewModel
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.thinMaterial, in: Capsule())
    }

    private enum ItemSheet: Identifiable {
        case createStory
        case createTask
        case editStory(UserStory)
        case editTask(Task)

        var id: String {
            switch self {
            case .createStory:
                return "create-story"
            case .createTask:
                return "create-task"
            case .editStory(let story):
                return "edit-story-\(story.id)"
            case .editTask(let task):
                return "edit-task-\(task.id)"
            }
        }
    }

    public var body: some View {
        content
        .navigationTitle("Backlog")
        .searchable(text: $searchText, prompt: "Search backlog")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Filter") {
                    Picker("Filter", selection: $displayFilter) {
                        ForEach(DisplayFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }

                    if case .loaded(let stories, let tasks, _) = viewModel.state {
                        Divider()

                        Picker("Status", selection: $statusFilter) {
                            Text("Any Status").tag(Optional<Int>.none)
                            ForEach(availableStatuses(stories: stories, tasks: tasks), id: \.self) { status in
                                Text("Status #\(status)").tag(Optional(status))
                            }
                        }

                        Picker("Assignee", selection: $assigneeFilter) {
                            Text("Any Assignee").tag(Optional<Int>.none)
                            ForEach(availableAssignees(stories: stories, tasks: tasks), id: \.self) { assignee in
                                Text("Assignee #\(assignee)").tag(Optional(assignee))
                            }
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu("Add") {
                    Button("New Story") { activeSheet = .createStory }
                    Button("New Task") { activeSheet = .createTask }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createStory:
                BacklogItemEditor(
                    title: "New Story",
                    submitTitle: "Create",
                    mode: .createStory,
                    availableStatuses: [],
                    availableAssignees: [],
                    onSubmit: { subject, _, _, _ in
                        try await viewModel.createStory(subject: subject)
                    }
                )

            case .createTask:
                BacklogItemEditor(
                    title: "New Task",
                    submitTitle: "Create",
                    mode: .createTask,
                    availableStatuses: [],
                    availableAssignees: [],
                    onSubmit: { subject, userStoryId, _, _ in
                        try await viewModel.createTask(subject: subject, userStoryId: userStoryId)
                    }
                )

            case .editStory(let story):
                BacklogItemEditor(
                    title: "Edit Story",
                    submitTitle: "Save",
                    mode: .editStory(story),
                    availableStatuses: availableStatusesFromState(),
                    availableAssignees: availableAssigneesFromState(),
                    onSubmit: { subject, _, status, assignee in
                        try await viewModel.updateStory(id: story.id, subject: subject, status: status, assignedTo: assignee)
                    }
                )

            case .editTask(let task):
                BacklogItemEditor(
                    title: "Edit Task",
                    submitTitle: "Save",
                    mode: .editTask(task),
                    availableStatuses: availableStatusesFromState(),
                    availableAssignees: availableAssigneesFromState(),
                    onSubmit: { subject, _, status, assignee in
                        try await viewModel.updateTask(id: task.id, subject: subject, status: status, assignedTo: assignee)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading…").task { await viewModel.load() }
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Swift.Task { await viewModel.load() } }
            }
        case .loaded(let stories, let tasks, let sprints):
            let filteredByAttributesStories = filteredStoriesByAttributes(stories)
            let filteredByAttributesTasks = filteredTasksByAttributes(tasks)
            let visibleStories = filteredStories(filteredByAttributesStories)
            let visibleTasks = filteredTasks(filteredByAttributesTasks)
            let visibleSprints = filteredSprints(sprints)
            List {
                if showsSprints && !visibleSprints.isEmpty {
                    Section("Sprints") {
                        ForEach(visibleSprints) { sprint in
                            VStack(alignment: .leading) {
                                Text(sprint.name).font(.headline)
                                if let start = sprint.estimatedStart, let end = sprint.estimatedFinish {
                                    Text("\(start) → \(end)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if showsStories && !visibleStories.isEmpty {
                    Section("User Stories") {
                        ForEach(visibleStories) { story in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(story.subject).font(.body)
                                HStack(spacing: 12) {
                                    if let status = story.status { badge("Status #\(status)") }
                                    if let assigned = story.assignedTo { badge("Assignee #\(assigned)") }
                                    if let points = story.points {
                                        let total = points.values.reduce(0, +)
                                        badge("\(total) pts")
                                    }
                                }
                            }
                            .swipeActions {
                                Button("Edit") { activeSheet = .editStory(story) }
                                    .tint(.blue)
                            }
                        }
                    }
                }
                if showsTasks && !visibleTasks.isEmpty {
                    Section("Tasks") {
                        ForEach(visibleTasks) { task in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.subject).font(.body)
                                HStack(spacing: 12) {
                                    if let status = task.status { badge("Status #\(status)") }
                                    if let assigned = task.assignedTo { badge("Assignee #\(assigned)") }
                                }
                            }
                            .swipeActions {
                                Button("Edit") { activeSheet = .editTask(task) }
                                    .tint(.blue)
                            }
                        }
                    }
                }

                if visibleStories.isEmpty && visibleTasks.isEmpty && visibleSprints.isEmpty {
                    Section {
                        ContentUnavailableView("No items found", systemImage: "magnifyingglass")
                    }
                }
            }
            .refreshable { await viewModel.load() }
            .safeAreaInset(edge: .bottom) {
                if let stamp = viewModel.lastUpdated {
                    Text("Updated \(stamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 8)
                }
            }
        }
    }

    private var showsSprints: Bool {
        displayFilter == .all || displayFilter == .sprints
    }

    private var showsStories: Bool {
        displayFilter == .all || displayFilter == .stories
    }

    private var showsTasks: Bool {
        displayFilter == .all || displayFilter == .tasks
    }

    private func filteredStories(_ stories: [UserStory]) -> [UserStory] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return stories }
        return stories.filter { $0.subject.localizedCaseInsensitiveContains(needle) }
    }

    private func filteredStoriesByAttributes(_ stories: [UserStory]) -> [UserStory] {
        stories.filter { story in
            let statusMatches = statusFilter == nil || story.status == statusFilter
            let assigneeMatches = assigneeFilter == nil || story.assignedTo == assigneeFilter
            return statusMatches && assigneeMatches
        }
    }

    private func filteredTasks(_ tasks: [Task]) -> [Task] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return tasks }
        return tasks.filter { $0.subject.localizedCaseInsensitiveContains(needle) }
    }

    private func filteredTasksByAttributes(_ tasks: [Task]) -> [Task] {
        tasks.filter { task in
            let statusMatches = statusFilter == nil || task.status == statusFilter
            let assigneeMatches = assigneeFilter == nil || task.assignedTo == assigneeFilter
            return statusMatches && assigneeMatches
        }
    }

    private func filteredSprints(_ sprints: [Sprint]) -> [Sprint] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return sprints }
        return sprints.filter {
            $0.name.localizedCaseInsensitiveContains(needle)
                || ($0.slug?.localizedCaseInsensitiveContains(needle) ?? false)
        }
    }

    private func availableStatuses(stories: [UserStory], tasks: [Task]) -> [Int] {
        let values = stories.compactMap(\.status) + tasks.compactMap(\.status)
        return Array(Set(values)).sorted()
    }

    private func availableAssignees(stories: [UserStory], tasks: [Task]) -> [Int] {
        let values = stories.compactMap(\.assignedTo) + tasks.compactMap(\.assignedTo)
        return Array(Set(values)).sorted()
    }

    private func availableStatusesFromState() -> [Int] {
        guard case .loaded(let stories, let tasks, _) = viewModel.state else { return [] }
        return availableStatuses(stories: stories, tasks: tasks)
    }

    private func availableAssigneesFromState() -> [Int] {
        guard case .loaded(let stories, let tasks, _) = viewModel.state else { return [] }
        return availableAssignees(stories: stories, tasks: tasks)
    }
}

private struct BacklogItemEditor: View {
    enum Mode {
        case createStory
        case createTask
        case editStory(UserStory)
        case editTask(Task)
    }

    let title: String
    let submitTitle: String
    let mode: Mode
    let availableStatuses: [Int]
    let availableAssignees: [Int]
    let onSubmit: (String, Int?, Int?, Int?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var userStoryIdText: String = ""
    @State private var status: Int?
    @State private var assignee: Int?
    @State private var isSaving = false
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Subject", text: $subject)
                    if showsUserStoryInput {
                        TextField("User Story ID (optional)", text: $userStoryIdText)
                            .keyboardType(.numberPad)
                    }
                }

                if showsStatusOrAssignee {
                    Section("Optional") {
                        if !availableStatuses.isEmpty {
                            Picker("Status", selection: $status) {
                                Text("Unchanged").tag(Optional<Int>.none)
                                ForEach(availableStatuses, id: \.self) { value in
                                    Text("Status #\(value)").tag(Optional(value))
                                }
                            }
                        }

                        if !availableAssignees.isEmpty {
                            Picker("Assignee", selection: $assignee) {
                                Text("Unassigned").tag(Optional<Int>.none)
                                ForEach(availableAssignees, id: \.self) { value in
                                    Text("Assignee #\(value)").tag(Optional(value))
                                }
                            }
                        }
                    }
                }

                if let validationError {
                    Section {
                        Text(validationError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(submitTitle) {
                        Swift.Task { await save() }
                    }
                    .disabled(subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .task { seedValuesIfNeeded() }
        }
    }

    private var showsUserStoryInput: Bool {
        if case .createTask = mode { return true }
        return false
    }

    private var showsStatusOrAssignee: Bool {
        switch mode {
        case .editStory, .editTask:
            return true
        default:
            return false
        }
    }

    private func seedValuesIfNeeded() {
        switch mode {
        case .editStory(let story):
            subject = story.subject
            status = story.status
            assignee = story.assignedTo
        case .editTask(let task):
            subject = task.subject
            status = task.status
            assignee = task.assignedTo
        default:
            break
        }
    }

    private func parsedUserStoryId() -> Int? {
        let raw = userStoryIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? nil : Int(raw)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let normalizedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSubject.isEmpty else {
            validationError = "Subject is required."
            return
        }

        if showsUserStoryInput && !userStoryIdText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedUserStoryId() == nil {
            validationError = "User Story ID must be a number."
            return
        }

        do {
            try await onSubmit(normalizedSubject, parsedUserStoryId(), status, assignee)
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }
    }
}

#Preview {
    ProjectDetailView(
        viewModel: ItemsViewModel(
            itemsService: ItemsService(),
            authService: AuthService(),
            projectId: 1
        )
    )
}
