import Foundation
import Observation
import TaigaCore

@Observable
public final class ProjectsViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([ProjectSummary])
        case failed(String)
    }

    @MainActor public private(set) var state: State = .idle
    @MainActor public private(set) var lastUpdated: Date?

    private let projectsService: ProjectsService
    private let authService: AuthService

    public init(projectsService: ProjectsService, authService: AuthService) {
        self.projectsService = projectsService
        self.authService = authService
    }

    @MainActor
    public func load() async {
        state = .loading
        do {
            let token = try await authService.authenticatedToken()
            let projects = try await projectsService.listProjects(using: token)
            state = .loaded(projects)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
