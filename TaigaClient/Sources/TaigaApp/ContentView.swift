import SwiftUI
import TaigaCore
import TaigaUI

struct ContentView: View {
    @State private var authViewModel: AuthViewModel
    @State private var projectsViewModel: ProjectsViewModel
    private let itemsService: ItemsService
    private let authService: AuthService

    init(authService: AuthService, projectsService: ProjectsService, itemsService: ItemsService = ItemsService()) {
        self.authService = authService
        self.itemsService = itemsService
        let authVM = AuthViewModel(authService: authService)
        _authViewModel = State(initialValue: authVM)
        _projectsViewModel = State(initialValue: ProjectsViewModel(projectsService: projectsService, authService: authService))
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
                        Task { @MainActor in
                            authViewModel.logout()
                        }
                    }
                )
            default:
                LoginView(viewModel: authViewModel, onReset: {
                    Task { @MainActor in
                        authViewModel.resetSession()
                    }
                })
            }
        }
    }
}

#Preview {
    ContentView(authService: AuthService(), projectsService: ProjectsService())
}
