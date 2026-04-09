import SwiftUI
import TaigaCore

public struct ProjectsListView: View {
    @Bindable private var viewModel: ProjectsViewModel
    @State private var searchText: String = ""
    private let itemsService: ItemsService
    private let authService: AuthService
    private let onLogout: () -> Void

    public init(viewModel: ProjectsViewModel, itemsService: ItemsService, authService: AuthService, onLogout: @escaping () -> Void) {
        self.viewModel = viewModel
        self.itemsService = itemsService
        self.authService = authService
        self.onLogout = onLogout
    }

    public var body: some View {
        content
        .navigationTitle("Projects")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            Button("Logout") { onLogout() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading projects…")
                .task { await viewModel.load() }
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Swift.Task { await viewModel.load() } }
            }
        case .loaded(let projects):
            List(filteredProjects(projects)) { project in
                NavigationLink {
                    ProjectDetailView(
                        viewModel: ItemsViewModel(
                            itemsService: itemsService,
                            authService: authService,
                            projectId: project.id
                        )
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                        if let description = project.description, !description.isEmpty {
                            Text(description)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Text(project.slug)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

    private func filteredProjects(_ projects: [ProjectSummary]) -> [ProjectSummary] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return projects }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(needle)
                || $0.slug.localizedCaseInsensitiveContains(needle)
                || ($0.description?.localizedCaseInsensitiveContains(needle) ?? false)
        }
    }
}

#Preview {
    ProjectsListView(
        viewModel: ProjectsViewModel(
            projectsService: ProjectsService(),
            authService: AuthService()
        ),
        itemsService: ItemsService(),
        authService: AuthService(),
        onLogout: {}
    )
}
