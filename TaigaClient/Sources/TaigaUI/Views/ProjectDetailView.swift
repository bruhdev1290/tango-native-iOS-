import SwiftUI
import TaigaCore
import UniformTypeIdentifiers

fileprivate struct BacklogDraft {
    let subject: String
    let userStoryId: Int?
    let description: String?
    let tags: [String]
    let assigneeMention: String?
    let attachments: [AttachmentUpload]
    let status: Int?
    let assignee: Int?
    let issueType: Int?
    let issueSeverity: Int?
    let issuePriority: Int?
}

private struct PickedAttachment: Identifiable {
    let id = UUID()
    let url: URL

    var fileName: String {
        url.lastPathComponent
    }

    var mimeType: String {
        let ext = url.pathExtension
        if let type = UTType(filenameExtension: ext), let preferred = type.preferredMIMEType {
            return preferred
        }
        return "application/octet-stream"
    }
}

public struct ProjectDetailView: View {
    private enum DisplayFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case sprints = "Sprints"
        case stories = "Stories"
        case tasks = "Tasks"
        case issues = "Issues"

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
        case createIssue
        case editStory(UserStory)
        case editTask(Task)
        case editIssue(Issue)

        var id: String {
            switch self {
            case .createStory:
                return "create-story"
            case .createTask:
                return "create-task"
            case .createIssue:
                return "create-issue"
            case .editStory(let story):
                return "edit-story-\(story.id)"
            case .editTask(let task):
                return "edit-task-\(task.id)"
            case .editIssue(let issue):
                return "edit-issue-\(issue.id)"
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

                    if case .loaded(let stories, let tasks, let issues, _) = viewModel.state {
                        Divider()

                        Picker("Status", selection: $statusFilter) {
                            Text("Any Status").tag(Optional<Int>.none)
                            ForEach(availableStatuses(stories: stories, tasks: tasks, issues: issues), id: \.self) { status in
                                Text("Status #\(status)").tag(Optional(status))
                            }
                        }

                        Picker("Assignee", selection: $assigneeFilter) {
                            Text("Any Assignee").tag(Optional<Int>.none)
                            ForEach(availableAssignees(stories: stories, tasks: tasks, issues: issues), id: \.self) { assignee in
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
                    Button("New Issue") { activeSheet = .createIssue }
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
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.createStory(
                            subject: draft.subject,
                            description: draft.description,
                            tags: draft.tags,
                            assigneeMention: draft.assigneeMention,
                            attachments: draft.attachments
                        )
                    }
                )

            case .createTask:
                BacklogItemEditor(
                    title: "New Task",
                    submitTitle: "Create",
                    mode: .createTask,
                    availableStatuses: [],
                    availableAssignees: [],
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.createTask(
                            subject: draft.subject,
                            userStoryId: draft.userStoryId,
                            assigneeMention: draft.assigneeMention
                        )
                    }
                )

            case .createIssue:
                BacklogItemEditor(
                    title: "New Issue",
                    submitTitle: "Create",
                    mode: .createIssue,
                    availableStatuses: [],
                    availableAssignees: [],
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.createIssue(
                            subject: draft.subject,
                            description: draft.description,
                            tags: draft.tags,
                            severity: draft.issueSeverity,
                            priority: draft.issuePriority,
                            issueType: draft.issueType,
                            assigneeMention: draft.assigneeMention,
                            attachments: draft.attachments
                        )
                    }
                )

            case .editStory(let story):
                BacklogItemEditor(
                    title: "Edit Story",
                    submitTitle: "Save",
                    mode: .editStory(story),
                    availableStatuses: availableStatusesFromState(),
                    availableAssignees: availableAssigneesFromState(),
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.updateStory(
                            id: story.id,
                            subject: draft.subject,
                            status: draft.status,
                            assignedTo: draft.assignee,
                            assigneeMention: draft.assigneeMention
                        )
                    }
                )

            case .editTask(let task):
                BacklogItemEditor(
                    title: "Edit Task",
                    submitTitle: "Save",
                    mode: .editTask(task),
                    availableStatuses: availableStatusesFromState(),
                    availableAssignees: availableAssigneesFromState(),
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.updateTask(
                            id: task.id,
                            subject: draft.subject,
                            status: draft.status,
                            assignedTo: draft.assignee,
                            assigneeMention: draft.assigneeMention
                        )
                    }
                )

            case .editIssue(let issue):
                BacklogItemEditor(
                    title: "Edit Issue",
                    submitTitle: "Save",
                    mode: .editIssue(issue),
                    availableStatuses: availableStatusesFromState(),
                    availableAssignees: availableAssigneesFromState(),
                    mentionSuggestions: viewModel.mentionSuggestions(for:),
                    onSubmit: { draft in
                        try await viewModel.updateIssue(
                            id: issue.id,
                            subject: draft.subject,
                            status: draft.status,
                            assignedTo: draft.assignee,
                            assigneeMention: draft.assigneeMention
                        )
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
        case .loaded(let stories, let tasks, let issues, let sprints):
            let filteredByAttributesStories = filteredStoriesByAttributes(stories)
            let filteredByAttributesTasks = filteredTasksByAttributes(tasks)
            let filteredByAttributesIssues = filteredIssuesByAttributes(issues)
            let visibleStories = filteredStories(filteredByAttributesStories)
            let visibleTasks = filteredTasks(filteredByAttributesTasks)
            let visibleIssues = filteredIssues(filteredByAttributesIssues)
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

                if showsIssues && !visibleIssues.isEmpty {
                    Section("Issues") {
                        ForEach(visibleIssues) { issue in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.subject).font(.body)
                                HStack(spacing: 12) {
                                    if let status = issue.status { badge("Status #\(status)") }
                                    if let assigned = issue.assignedTo { badge("Assignee #\(assigned)") }
                                }
                            }
                            .swipeActions {
                                Button("Edit") { activeSheet = .editIssue(issue) }
                                    .tint(.blue)
                            }
                        }
                    }
                }

                if visibleStories.isEmpty && visibleTasks.isEmpty && visibleIssues.isEmpty && visibleSprints.isEmpty {
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

    private var showsIssues: Bool {
        displayFilter == .all || displayFilter == .issues
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

    private func filteredIssues(_ issues: [Issue]) -> [Issue] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return issues }
        return issues.filter { $0.subject.localizedCaseInsensitiveContains(needle) }
    }

    private func filteredIssuesByAttributes(_ issues: [Issue]) -> [Issue] {
        issues.filter { issue in
            let statusMatches = statusFilter == nil || issue.status == statusFilter
            let assigneeMatches = assigneeFilter == nil || issue.assignedTo == assigneeFilter
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

    private func availableStatuses(stories: [UserStory], tasks: [Task], issues: [Issue]) -> [Int] {
        let values = stories.compactMap(\.status) + tasks.compactMap(\.status) + issues.compactMap(\.status)
        return Array(Set(values)).sorted()
    }

    private func availableAssignees(stories: [UserStory], tasks: [Task], issues: [Issue]) -> [Int] {
        let values = stories.compactMap(\.assignedTo) + tasks.compactMap(\.assignedTo) + issues.compactMap(\.assignedTo)
        return Array(Set(values)).sorted()
    }

    private func availableStatusesFromState() -> [Int] {
        guard case .loaded(let stories, let tasks, let issues, _) = viewModel.state else { return [] }
        return availableStatuses(stories: stories, tasks: tasks, issues: issues)
    }

    private func availableAssigneesFromState() -> [Int] {
        guard case .loaded(let stories, let tasks, let issues, _) = viewModel.state else { return [] }
        return availableAssignees(stories: stories, tasks: tasks, issues: issues)
    }
}

private struct BacklogItemEditor: View {
    enum Mode {
        case createStory
        case createTask
        case createIssue
        case editStory(UserStory)
        case editTask(Task)
        case editIssue(Issue)
    }

    let title: String
    let submitTitle: String
    let mode: Mode
    let availableStatuses: [Int]
    let availableAssignees: [Int]
    let mentionSuggestions: (String) -> [ItemsViewModel.MentionCandidate]
    let onSubmit: (BacklogDraft) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var userStoryIdText: String = ""
    @State private var descriptionText: String = ""
    @State private var tagsText: String = ""
    @State private var issueTypeText: String = ""
    @State private var issueSeverityText: String = ""
    @State private var issuePriorityText: String = ""
    @State private var assigneeMentionText: String = ""
    @State private var selectedAttachments: [PickedAttachment] = []
    @State private var showsFileImporter = false
    @State private var status: Int?
    @State private var assignee: Int?
    @State private var isSaving = false
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Subject", text: $subject)
                    if supportsMentionAssignment {
                        TextField("Assign (@me, @username, @123)", text: $assigneeMentionText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    if showsDescriptionInput {
                        TextField("Description", text: $descriptionText, axis: .vertical)
                            .lineLimit(4...10)
                    }
                    if showsTagsInput {
                        TextField("Tags (comma separated)", text: $tagsText)
                    }
                    if showsUserStoryInput {
                        TextField("User Story ID (optional)", text: $userStoryIdText)
                            .keyboardType(.numberPad)
                    }
                }

                if !resolvedMentionSuggestions.isEmpty {
                    Section("People") {
                        ForEach(resolvedMentionSuggestions) { candidate in
                            Button {
                                assigneeMentionText = candidate.mentionValue
                            } label: {
                                HStack(spacing: 10) {
                                    avatarView(urlString: candidate.avatarURL)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.displayName)
                                            .foregroundStyle(.primary)
                                        Text(candidate.handle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if showsIssueFields {
                    Section("Issue Fields") {
                        TextField("Type ID (optional)", text: $issueTypeText)
                            .keyboardType(.numberPad)
                        TextField("Severity ID (optional)", text: $issueSeverityText)
                            .keyboardType(.numberPad)
                        TextField("Priority ID (optional)", text: $issuePriorityText)
                            .keyboardType(.numberPad)
                    }
                }

                if supportsAttachments {
                    Section("Attachments") {
                        Button("Add Files") {
                            showsFileImporter = true
                        }

                        if selectedAttachments.isEmpty {
                            Text("No files selected")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(selectedAttachments) { attachment in
                                Text(attachment.fileName)
                            }
                            .onDelete { indexes in
                                selectedAttachments.remove(atOffsets: indexes)
                            }
                        }
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
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            do {
                let urls = try result.get()
                let incoming = urls.map(PickedAttachment.init(url:))
                selectedAttachments.append(contentsOf: incoming)
            } catch {
                validationError = error.localizedDescription
            }
        }
    }

    private var showsUserStoryInput: Bool {
        if case .createTask = mode { return true }
        return false
    }

    private var showsDescriptionInput: Bool {
        switch mode {
        case .createStory, .createIssue:
            return true
        default:
            return false
        }
    }

    private var showsTagsInput: Bool {
        switch mode {
        case .createStory, .createIssue:
            return true
        default:
            return false
        }
    }

    private var showsIssueFields: Bool {
        if case .createIssue = mode { return true }
        return false
    }

    private var supportsAttachments: Bool {
        switch mode {
        case .createStory, .createIssue:
            return true
        default:
            return false
        }
    }

    private var supportsMentionAssignment: Bool {
        true
    }

    private var resolvedMentionSuggestions: [ItemsViewModel.MentionCandidate] {
        mentionSuggestions(assigneeMentionText)
    }

    private var showsStatusOrAssignee: Bool {
        switch mode {
        case .editStory, .editTask, .editIssue:
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
            if let assigned = story.assignedTo {
                assigneeMentionText = "@\(assigned)"
            }
        case .editTask(let task):
            subject = task.subject
            status = task.status
            assignee = task.assignedTo
            if let assigned = task.assignedTo {
                assigneeMentionText = "@\(assigned)"
            }
        case .editIssue(let issue):
            subject = issue.subject
            status = issue.status
            assignee = issue.assignedTo
            if let assigned = issue.assignedTo {
                assigneeMentionText = "@\(assigned)"
            }
        default:
            break
        }
    }

    private func parsedUserStoryId() -> Int? {
        let raw = userStoryIdText.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? nil : Int(raw)
    }

    private func parsedOptionalInt(_ raw: String) -> Int? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : Int(value)
    }

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func attachmentUploads() throws -> [AttachmentUpload] {
        var uploads: [AttachmentUpload] = []

        for attachment in selectedAttachments {
            let didAccess = attachment.url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    attachment.url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: attachment.url)
            uploads.append(
                AttachmentUpload(
                    fileName: attachment.fileName,
                    mimeType: attachment.mimeType,
                    data: data
                )
            )
        }

        return uploads
    }

    @ViewBuilder
    private func avatarView(urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
        }
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

        if showsIssueFields {
            let invalidType = !issueTypeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedOptionalInt(issueTypeText) == nil
            let invalidSeverity = !issueSeverityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedOptionalInt(issueSeverityText) == nil
            let invalidPriority = !issuePriorityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedOptionalInt(issuePriorityText) == nil
            if invalidType || invalidSeverity || invalidPriority {
                validationError = "Issue Type, Severity, and Priority IDs must be numeric when provided."
                return
            }
        }

        if !assigneeMentionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = assigneeMentionText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.hasPrefix("@") {
                validationError = "Assignee mention must start with @ (for example: @me)."
                return
            }
        }

        do {
            let normalizedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            let uploads = try attachmentUploads()
            let normalizedMention = assigneeMentionText.trimmingCharacters(in: .whitespacesAndNewlines)
            try await onSubmit(
                .init(
                    subject: normalizedSubject,
                    userStoryId: parsedUserStoryId(),
                    description: normalizedDescription.isEmpty ? nil : normalizedDescription,
                    tags: parsedTags(),
                    assigneeMention: normalizedMention.isEmpty ? nil : normalizedMention,
                    attachments: uploads,
                    status: status,
                    assignee: assignee,
                    issueType: parsedOptionalInt(issueTypeText),
                    issueSeverity: parsedOptionalInt(issueSeverityText),
                    issuePriority: parsedOptionalInt(issuePriorityText)
                )
            )
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
