import Foundation

public struct TaigaAPIClient: Sendable {
    public let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL = URL(string: "https://api.taiga.io/api/v1")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func login(username: String, password: String, type: String = "normal") async throws -> AuthToken {
        var request = URLRequest(url: baseURL.appending(path: "auth"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "type": type,
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TaigaError.unknown }
            switch http.statusCode {
            case 200:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                guard let token = try? decoder.decode(AuthToken.self, from: data) else {
                    throw TaigaError.decoding
                }
                return token
            case 400:
                throw TaigaError.invalidCredentials
            default:
                throw TaigaError.http(status: http.statusCode)
            }
        } catch let error as TaigaError {
            throw error
        } catch {
            throw TaigaError.network(underlying: error)
        }
    }

    public func fetchProjects(token: AuthToken) async throws -> [ProjectSummary] {
        try await authorizedGet(path: "projects", token: token)
    }

    public func fetchUserStories(projectId: Int, token: AuthToken) async throws -> [UserStory] {
        try await authorizedGet(path: "userstories", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func fetchTasks(projectId: Int, token: AuthToken) async throws -> [Task] {
        try await authorizedGet(path: "tasks", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func fetchSprints(projectId: Int, token: AuthToken) async throws -> [Sprint] {
        try await authorizedGet(path: "milestones", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func refresh(refreshToken: String) async throws -> AuthToken {
        var request = URLRequest(url: baseURL.appending(path: "auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refresh": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TaigaError.unknown }
            guard http.statusCode == 200 else { throw TaigaError.http(status: http.statusCode) }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let token = try? decoder.decode(AuthToken.self, from: data) else {
                throw TaigaError.decoding
            }
            return token
        } catch let error as TaigaError {
            throw error
        } catch {
            throw TaigaError.network(underlying: error)
        }
    }

    // MARK: - Helpers

    private func authorizedGet<T: Decodable>(path: String, token: AuthToken, queryItems: [URLQueryItem]? = nil) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        guard let url = components.url else { throw TaigaError.unknown }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TaigaError.unknown }
            guard 200..<300 ~= http.statusCode else {
                throw TaigaError.http(status: http.statusCode)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let decoded = try? decoder.decode(T.self, from: data) else {
                throw TaigaError.decoding
            }
            return decoded
        } catch let error as TaigaError {
            throw error
        } catch {
            throw TaigaError.network(underlying: error)
        }
    }
}
