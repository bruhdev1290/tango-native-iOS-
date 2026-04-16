import SwiftUI
import TaigaCore
import TaigaUI

struct ContentView: View {
    @State private var authViewModel: AuthViewModel
    @State private var projectsViewModel: ProjectsViewModel
    @State private var showsSplash = false
    @State private var isLocked = false
    @State private var securityEnabled = false
    private let apiClient: TaigaAPIClient
    private let itemsService: ItemsService
    private let projectsService: ProjectsService
    private let authService: AuthService
    private let gitHubConfig: GitHubOAuthConfig
    private let securityService = SecurityLockService()

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

        let hasSeenSplash = UserDefaults.standard.bool(forKey: "has-seen-splash-screen")
        _showsSplash = State(initialValue: !hasSeenSplash)
    }

    var body: some View {
        ZStack {
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
                        enableGitHubAuth: false,
                        onReset: {
                            await MainActor.run {
                                authViewModel.resetSession()
                            }
                        }
                    )
                }
            }

            if showsSplash {
                SplashScreenView {
                    UserDefaults.standard.set(true, forKey: "has-seen-splash-screen")
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showsSplash = false
                    }
                }
                .transition(AnyTransition.opacity)
            }

            if isLocked {
                AppLockOverlayView(
                    securityService: securityService,
                    onUnlock: {
                        withAnimation {
                            isLocked = false
                        }
                    },
                    onLogout: {
                        Swift.Task { @MainActor in
                            authViewModel.logout()
                            isLocked = false
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .task {
            let enabled = await securityService.isPasscodeSet()
            await MainActor.run {
                securityEnabled = enabled
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            Swift.Task {
                let enabled = await securityService.isPasscodeSet()
                await MainActor.run {
                    securityEnabled = enabled
                    if securityEnabled {
                        switch authViewModel.state {
                        case .authenticated:
                            isLocked = true
                        default:
                            break
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Swift.Task {
                let enabled = await securityService.isPasscodeSet()
                await MainActor.run {
                    securityEnabled = enabled
                }
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
