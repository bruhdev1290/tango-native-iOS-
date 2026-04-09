import SwiftUI
import TaigaCore
import TaigaUI

@main
struct TaigaMobileApp: App {
    private enum AppearanceMode: String {
        case system
        case light
        case dark

        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    private enum AccentColorOption: String {
        case system
        case blue
        case green
        case orange
        case red

        var color: Color {
            switch self {
            case .system:
                return .accentColor
            case .blue:
                return .blue
            case .green:
                return .green
            case .orange:
                return .orange
            case .red:
                return .red
            }
        }
    }

    @AppStorage("app-appearance-mode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("app-accent-color") private var accentColorRaw: String = AccentColorOption.system.rawValue
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
            .preferredColorScheme(appearanceMode.colorScheme)
            .tint(accentColor.color)
        }
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var accentColor: AccentColorOption {
        AccentColorOption(rawValue: accentColorRaw) ?? .system
    }
}
