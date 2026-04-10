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
        case blueberry
        case strawberry
        case orange
        case banana
        case green
        case mint
        case teal
        case grape
        case pink
        case platinum
        case indigo

        var color: Color {
            switch self {
            case .blueberry: return Color(red: 0.0, green: 0.48, blue: 1.0)
            case .strawberry: return Color(red: 1.0, green: 0.27, blue: 0.23)
            case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)
            case .banana: return Color(red: 1.0, green: 0.8, blue: 0.0)
            case .green: return Color(red: 0.2, green: 0.78, blue: 0.35)
            case .mint: return Color(red: 0.0, green: 0.78, blue: 0.75)
            case .teal: return Color(red: 0.35, green: 0.78, blue: 0.85)
            case .grape: return Color(red: 0.6, green: 0.4, blue: 0.9)
            case .pink: return Color(red: 1.0, green: 0.3, blue: 0.5)
            case .platinum: return Color(red: 0.55, green: 0.55, blue: 0.58)
            case .indigo: return Color(red: 0.35, green: 0.35, blue: 0.85)
            }
        }
    }

    @AppStorage("app-appearance-mode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("app-accent-color") private var accentColorRaw: String = AccentColorOption.blueberry.rawValue
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
        AccentColorOption(rawValue: accentColorRaw) ?? .blueberry
    }
}
