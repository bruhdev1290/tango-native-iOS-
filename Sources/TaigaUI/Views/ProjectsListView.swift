import SwiftUI
import TaigaCore

public struct ProjectsListView: View {
    private enum HomeTab: String, CaseIterable, Identifiable {
        case home = "Home"
        case activity = "Activity"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home:
                return "house.fill"
            case .activity:
                return "waveform.path.ecg"
            }
        }
    }

    @Bindable private var viewModel: ProjectsViewModel
    @Namespace private var tabAnimation
    @State private var showsSettings = false
    @State private var showsProjectSearch = false
    @State private var showsActivityFilters = false
    @State private var selectedTab: HomeTab = .home
    @State private var activityKindFilters: Set<ActivityItem.Kind> = [.story, .task, .issue]
    @State private var activityScopeFilters: Set<ActivityItem.Scope> = [.assigned, .memberProject]
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
                HStack(spacing: 14) {
                    if selectedTab == .activity {
                        Button {
                            showsActivityFilters = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    } else {
                        Button {
                            showsProjectSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }

                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .sheet(isPresented: $showsSettings) {
            AppSettingsView(onLogout: onLogout)
        }
        .sheet(isPresented: $showsProjectSearch) {
            ProjectSearchView(
                projects: allLoadedProjects,
                itemsService: itemsService,
                authService: authService
            )
        }
        .sheet(isPresented: $showsActivityFilters) {
            ActivityFiltersView(
                kindFilters: $activityKindFilters,
                scopeFilters: $activityScopeFilters
            )
        }
    }

    private var allLoadedProjects: [ProjectSummary] {
        guard case .loaded(let projects, _, _, _, _) = viewModel.state else { return [] }
        return projects
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
            let activity,
            let username,
            let relatedProjectIds
        ):
            loadedView(
                projects: projects,
                myWork: myWork,
                activity: activity,
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
        activity: [ActivityItem],
        username: String?
    ) -> some View {
        let projectsById = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Group {
                    if selectedTab == .home {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Hello, \(username ?? "there")")
                                .font(.title2.weight(.bold))
                                .padding(.top, 8)

                            if !myWork.isEmpty {
                                myWorkSection(items: myWork, projectsById: projectsById)
                            }

                            projectsSection(projects: projects)
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    } else {
                        let filteredActivity = activity.filter { item in
                            activityKindFilters.contains(item.kind) && activityScopeFilters.contains(item.scope)
                        }
                        activitySection(items: filteredActivity, projectsById: projectsById)
                            .padding(.top, 8)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)), removal: .opacity.combined(with: .move(edge: .trailing))))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.86), value: selectedTab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .refreshable { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if let stamp = viewModel.lastUpdated {
                    Text("Updated \(stamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                liquidGlassMenuBar()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private func liquidGlassMenuBar() -> some View {
        HStack(spacing: 6) {
            ForEach(HomeTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.7),
                                            Color.white.opacity(0.55)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.7),
                                                    Color.white.opacity(0.3)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .matchedGeometryEffect(id: "tab-highlight", in: tabAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.12)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.25)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .background(.ultraThinMaterial, in: Capsule())
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func activitySection(items: [ActivityItem], projectsById: [Int: ProjectSummary]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity")
                .font(.headline)

            if items.isEmpty {
                ContentUnavailableView("No recent activity", systemImage: "tray")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            } else {
                LazyVStack(spacing: 10) {
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
                            ActivityRow(item: item, project: projectsById[item.projectId])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func myWorkSection(items: [MyWorkItem], projectsById: [Int: ProjectSummary]) -> some View {
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
                            MyWorkCard(item: item, project: projectsById[item.projectId])
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

private struct ProjectSearchView: View {
    let projects: [ProjectSummary]
    let itemsService: ItemsService
    let authService: AuthService

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredProjects: [ProjectSummary] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return projects }
        return projects.filter { project in
            project.name.localizedCaseInsensitiveContains(needle)
                || project.slug.localizedCaseInsensitiveContains(needle)
                || (project.description?.localizedCaseInsensitiveContains(needle) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredProjects.isEmpty {
                    ContentUnavailableView("No matching projects", systemImage: "magnifyingglass")
                } else {
                    ForEach(filteredProjects) { project in
                        NavigationLink {
                            ProjectDetailView(
                                viewModel: ItemsViewModel(
                                    itemsService: itemsService,
                                    authService: authService,
                                    projectId: project.id
                                )
                            )
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(.blue, in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Text(project.slug)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search all projects")
            .navigationTitle("Project Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - My Work Card

private struct MyWorkCard: View {
    let item: MyWorkItem
    let project: ProjectSummary?

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

    private var projectColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .teal, .indigo, .mint, .cyan]
        let hash = abs(item.projectName.hashValue)
        return colors[hash % colors.count]
    }

    private var projectInitials: String {
        let words = item.projectName.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }

    private var projectLogoURL: URL? {
        if let small = project?.logoSmallURL, let url = URL(string: small) {
            return url
        }
        if let big = project?.logoBigURL, let url = URL(string: big) {
            return url
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Group {
                    if let projectLogoURL {
                        AsyncImage(url: projectLogoURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Text(projectInitials)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(projectColor)
                            }
                        }
                    } else {
                        Text(projectInitials)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(projectColor)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
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

private struct ActivityRow: View {
    let item: ActivityItem
    let project: ProjectSummary?

    private var kindColor: Color {
        switch item.kind {
        case .story: return .blue
        case .task: return .green
        case .issue: return .orange
        }
    }

    private var projectLogoURL: URL? {
        if let small = project?.logoSmallURL, let url = URL(string: small) {
            return url
        }
        if let big = project?.logoBigURL, let url = URL(string: big) {
            return url
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let projectLogoURL {
                    AsyncImage(url: projectLogoURL) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.gray)
                        }
                    }
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.gray)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.subject)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(item.projectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.kind.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(kindColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(kindColor.opacity(0.12), in: Capsule())

            Text(item.scope.rawValue)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
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

    private var projectLogoURL: URL? {
        if let small = project.logoSmallURL, let url = URL(string: small) {
            return url
        }
        if let big = project.logoBigURL, let url = URL(string: big) {
            return url
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // Project Icon
            Group {
                if let projectLogoURL {
                    AsyncImage(url: projectLogoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Text(initials)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(projectColor)
                        }
                    }
                } else {
                    Text(initials)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(projectColor)
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 10))

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

// MARK: - Activity Filters View

private struct ActivityFiltersView: View {
    @Binding var kindFilters: Set<ActivityItem.Kind>
    @Binding var scopeFilters: Set<ActivityItem.Scope>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Type") {
                    Toggle("Stories", isOn: Binding(
                        get: { kindFilters.contains(.story) },
                        set: { if $0 { kindFilters.insert(.story) } else { kindFilters.remove(.story) } }
                    ))
                    Toggle("Tasks", isOn: Binding(
                        get: { kindFilters.contains(.task) },
                        set: { if $0 { kindFilters.insert(.task) } else { kindFilters.remove(.task) } }
                    ))
                    Toggle("Issues", isOn: Binding(
                        get: { kindFilters.contains(.issue) },
                        set: { if $0 { kindFilters.insert(.issue) } else { kindFilters.remove(.issue) } }
                    ))
                }

                Section("Source") {
                    Toggle("Assigned to Me", isOn: Binding(
                        get: { scopeFilters.contains(.assigned) },
                        set: { if $0 { scopeFilters.insert(.assigned) } else { scopeFilters.remove(.assigned) } }
                    ))
                    Toggle("In My Projects", isOn: Binding(
                        get: { scopeFilters.contains(.memberProject) },
                        set: { if $0 { scopeFilters.insert(.memberProject) } else { scopeFilters.remove(.memberProject) } }
                    ))
                }

                Section {
                    Button("Reset to Defaults") {
                        kindFilters = [.story, .task, .issue]
                        scopeFilters = [.assigned, .memberProject]
                    }
                }
            }
            .navigationTitle("Filter Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
