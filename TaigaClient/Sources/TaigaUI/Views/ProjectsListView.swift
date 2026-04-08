import SwiftUI
import TaigaCore

public struct ProjectsListView: View {
    @Bindable private var viewModel: ProjectsViewModel
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
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Loading projects…")
                    .task { await viewModel.load() }
            case .failed(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(message).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.load() } }
                }
            case .loaded(let projects):
                List(projects) { project in
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
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            Button("Logout") { onLogout() }
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
