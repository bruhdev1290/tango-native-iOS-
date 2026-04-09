import SwiftUI
import TaigaCore
import TaigaUI

@main
struct TaigaMobileApp: App {
    private let apiClient: TaigaAPIClient
    private let authService: AuthService
    private let projectsService: ProjectsService
    private let itemsService: ItemsService

    // MARK: - GitHub OAuth Configuration
    // To enable GitHub authentication:
    // 1. Create a GitHub OAuth App at https://github.com/settings/developers
    // 2. Set the callback URL to: taiga://callback (or your custom scheme)
    // 3. Copy the Client ID and paste it below
    // 4. Add the URL scheme to your Info.plist
    private let gitHubConfig = GitHubOAuthConfig(
        clientId: "", // Add your GitHub Client ID here
        callbackURLScheme: "taiga"
    )

    init() {
        let storedBaseURL = UserDefaults.standard.string(forKey: "taiga-base-url")
        let resolvedBaseURL = storedBaseURL.flatMap(TaigaAPIClient.normalizedBaseURL(from:)) ?? TaigaAPIClient.defaultBaseURL
        let apiClient = TaigaAPIClient(baseURL: resolvedBaseURL)

        self.apiClient = apiClient
        self.authService = AuthService(api: apiClient)
        self.projectsService = ProjectsService(api: apiClient)
        self.itemsService = ItemsService(api: apiClient)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                apiClient: apiClient,
                authService: authService,
                projectsService: projectsService,
                itemsService: itemsService,
                gitHubConfig: gitHubConfig
            )
        }
    }
}
