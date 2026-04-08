import Foundation

public actor ProjectsService {
    private let api: TaigaAPIClient

    public init(api: TaigaAPIClient = TaigaAPIClient()) {
        self.api = api
    }

    public func listProjects(using token: AuthToken) async throws -> [ProjectSummary] {
        try await api.fetchProjects(token: token)
    }
}
