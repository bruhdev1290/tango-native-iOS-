import SwiftUI
import TaigaCore

public struct ProjectDetailView: View {
    @Bindable private var viewModel: ItemsViewModel

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

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading…").task { await viewModel.load() }
            case .failed(let message):
                VStack(spacing: 12) {
                    Text(message).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.load() } }
                }
            case .loaded(let stories, let tasks, let sprints):
                List {
                    if !sprints.isEmpty {
                        Section("Sprints") {
                            ForEach(sprints) { sprint in
                                VStack(alignment: .leading) {
                                    Text(sprint.name).font(.headline)
                                    if let start = sprint.estimatedStart, let end = sprint.estimatedFinish {
                                        Text("\(start) → \(end)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    if !stories.isEmpty {
                        Section("User Stories") {
                            ForEach(stories) { story in
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
                                    Button("Edit") { /* wire later */ }
                                        .tint(.blue)
                                }
                            }
                        }
                    }
                    if !tasks.isEmpty {
                        Section("Tasks") {
                            ForEach(tasks) { task in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.subject).font(.body)
                                    HStack(spacing: 12) {
                                        if let status = task.status { badge("Status #\(status)") }
                                        if let assigned = task.assignedTo { badge("Assignee #\(assigned)") }
                                    }
                                }
                                .swipeActions {
                                    Button("Edit") { /* wire later */ }
                                        .tint(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Backlog")
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
