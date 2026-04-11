import SwiftUI
import TaigaCore
import TaigaUI

struct ContentView: View {
    @State private var authViewModel: AuthViewModel
    @State private var projectsViewModel: ProjectsViewModel
    private let apiClient: TaigaAPIClient
    private let itemsService: ItemsService
    private let projectsService: ProjectsService
    private let authService: AuthService
    private let gitHubConfig: GitHubOAuthConfig

    init(
        apiClient: TaigaAPIClient,
        authService: AuthService,
        projectsService: ProjectsService,
        itemsService: ItemsService = ItemsService(),
        gitHubConfig: GitHubOAuthConfig = .default
    ) {
        self.apiClient = apiClient
        self.authService = authService
        self.itemsService = itemsService
        self.projectsService = projectsService
        self.gitHubConfig = gitHubConfig
        let authVM = AuthViewModel(authService: authService, gitHubConfig: gitHubConfig)
        _authViewModel = State(initialValue: authVM)
        _projectsViewModel = State(initialValue: ProjectsViewModel(
            projectsService: projectsService,
            authService: authService
        ))
    }

    var body: some View {
        NavigationStack {
            switch authViewModel.state {
            case .authenticated:
                ProjectsListView(
                    viewModel: projectsViewModel,
                    itemsService: itemsService,
                    authService: authService,
                    onLogout: {
                        Swift.Task { @MainActor in
                            authViewModel.logout()
                        }
                    }
                )
            default:
                LoginView(
                    viewModel: authViewModel,
                    apiClient: apiClient,
                    enableGitHubAuth: gitHubConfig.isEnabled,
                    onReset: {
                        await MainActor.run {
                            authViewModel.resetSession()
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    let apiClient = TaigaAPIClient()
    ContentView(
        apiClient: apiClient,
        authService: AuthService(api: apiClient),
        projectsService: ProjectsService(api: apiClient),
        itemsService: ItemsService(api: apiClient)
    )
}
