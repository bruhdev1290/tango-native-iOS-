import SwiftUI
import TaigaCore

public struct ProjectsListView: View {
    @Bindable private var viewModel: ProjectsViewModel
    @State private var showsSettings = false
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
        .toolbar {
            Button("Logout") { onLogout() }
        }
        .sheet(isPresented: $showsSettings) {
            AppSettingsView()
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
        case .loaded(
            let projects,
            let myWork,
            let username,
            let relatedProjectIds
        ):
            let relatedSet = Set(relatedProjectIds)
            let myProjects = projects.filter { relatedSet.contains($0.id) }
            List {
                Section {
                    HStack {
                        Text("My Work")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())

                        Spacer()

                        Button {
                            showsSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.body.weight(.semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }

                let visibleMyWork = myWork
                Section(username.map { "My Work (\($0))" } ?? "My Work") {
                    if visibleMyWork.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No assigned items found")
                                .font(.headline)
                            Text("Your assigned stories/tasks/issues will show here.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(visibleMyWork) { item in
                            NavigationLink {
                                ProjectDetailView(
                                    viewModel: ItemsViewModel(
                                        itemsService: itemsService,
                                        authService: authService,
                                        projectId: item.projectId
                                    )
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.subject)
                                        .font(.headline)
                                        .lineLimit(2)
                                    HStack(spacing: 8) {
                                        Text(item.projectName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(item.kind.rawValue)
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(.thinMaterial, in: Capsule())
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Your Projects") {
                    if myProjects.isEmpty {
                        Text("No related projects yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(myProjects) { project in
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
