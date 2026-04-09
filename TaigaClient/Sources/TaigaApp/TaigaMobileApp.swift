import SwiftUI
import TaigaCore
import TaigaUI

@main
struct TaigaMobileApp: App {
    private let authService = AuthService()
    private let projectsService = ProjectsService()

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

    var body: some Scene {
        WindowGroup {
            ContentView(
                authService: authService,
                projectsService: projectsService,
                gitHubConfig: gitHubConfig
            )
        }
    }
}
