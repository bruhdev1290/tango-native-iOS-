import SwiftUI
import TaigaCore
import TaigaUI

@main
struct TaigaMobileApp: App {
    private let authService = AuthService()
    private let projectsService = ProjectsService()

    var body: some Scene {
        WindowGroup {
            ContentView(authService: authService, projectsService: projectsService)
        }
    }
}
