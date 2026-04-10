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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                    }
                    
                    Button("Logout") {
                        onLogout()
                    }
                    .font(.subheadline)
                }
            }
        }
        .sheet(isPresented: $showsSettings) {
            AppSettingsView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .failed(let message):
            errorView(message: message)
        case .loaded(
            let projects,
            let myWork,
            let username,
            let relatedProjectIds
        ):
            let relatedSet = Set(relatedProjectIds)
            let myProjects = projects.filter { relatedSet.contains($0.id) }
            loadedView(
                projects: myProjects,
                myWork: myWork,
                username: username
            )
        }
    }

    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.2)
            .task { await viewModel.load() }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Swift.Task { await viewModel.load() }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 32)
    }

    private func loadedView(
        projects: [ProjectSummary],
        myWork: [MyWorkItem],
        username: String?
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Welcome
                Text("Hello, \(username ?? "there")")
                    .font(.title2.weight(.bold))
                    .padding(.top, 8)

                // My Work Section
                if !myWork.isEmpty {
                    myWorkSection(items: myWork)
                }

                // Projects Section
                projectsSection(projects: projects)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
        .refreshable { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let stamp = viewModel.lastUpdated {
                Text("Updated \(stamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }

    private func myWorkSection(items: [MyWorkItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Work")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            ProjectDetailView(
                                viewModel: ItemsViewModel(
                                    itemsService: itemsService,
                                    authService: authService,
                                    projectId: item.projectId
                                )
                            )
                        } label: {
                            MyWorkCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func projectsSection(projects: [ProjectSummary]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Projects")
                .font(.headline)
            
            if projects.isEmpty {
                emptyProjectsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(projects) { project in
                        NavigationLink {
                            ProjectDetailView(
                                viewModel: ItemsViewModel(
                                    itemsService: itemsService,
                                    authService: authService,
                                    projectId: project.id
                                )
                            )
                        } label: {
                            CompactProjectCard(project: project)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyProjectsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No projects yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - My Work Card

private struct MyWorkCard: View {
    let item: MyWorkItem

    private var iconName: String {
        switch item.kind {
        case .story: return "book.fill"
        case .task: return "checkmark.circle.fill"
        case .issue: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch item.kind {
        case .story: return .blue
        case .task: return .green
        case .issue: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                
                Spacer()
                
                Text(item.kind.rawValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(iconColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(iconColor.opacity(0.12), in: Capsule())
            }
            
            Text(item.subject)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.caption2)
                Text(item.projectName)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 170, height: 130, alignment: .leading)
        .background(.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Compact Project Card

private struct CompactProjectCard: View {
    let project: ProjectSummary

    private var projectColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .teal, .indigo, .mint, .cyan]
        let hash = abs(project.name.hashValue)
        return colors[hash % colors.count]
    }

    private var initials: String {
        let words = project.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Project Icon
            Text(initials)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(projectColor, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
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
}
