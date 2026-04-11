import Foundation

public final class TaigaAPIConfiguration: @unchecked Sendable {
    public var baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
}

public struct TaigaAPIClient: @unchecked Sendable {
    public static let defaultBaseURL = URL(string: "https://api.taiga.io/api/v1")!

    private let configuration: TaigaAPIConfiguration
    private let session: URLSession

    public init(baseURL: URL = Self.defaultBaseURL, session: URLSession = .shared) {
        self.configuration = TaigaAPIConfiguration(baseURL: Self.normalizeBaseURL(baseURL))
        self.session = session
    }

    public init(configuration: TaigaAPIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public var baseURL: URL {
        configuration.baseURL
    }

    public func updateBaseURL(_ baseURL: URL) {
        configuration.baseURL = Self.normalizeBaseURL(baseURL)
    }

    public static func normalizedBaseURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let prefixed: String
        if trimmed.contains("://") {
            prefixed = trimmed
        } else {
            prefixed = "https://\(trimmed)"
        }

        guard var components = URLComponents(string: prefixed) else { return nil }
        if components.host == "tree.taiga.io" {
            components.host = "api.taiga.io"
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let pathSegments = path.split(separator: "/").map(String.init)

        if pathSegments.suffix(2) == ["api", "v1"] {
            components.path = "/" + pathSegments.joined(separator: "/")
        } else if pathSegments.isEmpty {
            components.path = "/api/v1"
        } else {
            components.path = "/" + pathSegments.joined(separator: "/") + "/api/v1"
        }

        return components.url
    }

    private static func normalizeBaseURL(_ baseURL: URL) -> URL {
        guard let normalized = normalizedBaseURL(from: baseURL.absoluteString) else {
            return baseURL
        }
        return normalized
    }

    public func login(username: String, password: String, type: String = "normal") async throws -> AuthToken {
        var request = URLRequest(url: baseURL.appending(path: "auth"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

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

    public func loginWithGitHub(code: String) async throws -> AuthToken {
        var request = URLRequest(url: baseURL.appending(path: "auth"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: String] = [
            "type": "github",
            "code": code
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
                // Try to parse error details from Taiga
                if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorDetail = dict["detail"] as? String {
                    throw TaigaError.gitHubAuthFailed(errorDetail)
                }
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

    public func fetchProjects(memberId: Int, token: AuthToken) async throws -> [ProjectSummary] {
        try await authorizedGet(
            path: "projects",
            token: token,
            queryItems: [
                URLQueryItem(name: "member", value: "\(memberId)"),
                URLQueryItem(name: "order_by", value: "memberships__user_order")
            ],
            disablePagination: true
        )
    }

    public func fetchCurrentUser(token: AuthToken) async throws -> CurrentUser {
        try await authorizedGet(path: "users/me", token: token)
    }

    public func fetchMemberships(projectId: Int, token: AuthToken) async throws -> [Membership] {
        try await authorizedGet(
            path: "memberships",
            token: token,
            queryItems: [URLQueryItem(name: "project", value: "\(projectId)")],
            disablePagination: true
        )
    }

    public func fetchUserStories(projectId: Int, token: AuthToken) async throws -> [UserStory] {
        try await authorizedGet(path: "userstories", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func fetchAssignedUserStories(assigneeId: Int, token: AuthToken) async throws -> [UserStory] {
        try await authorizedGet(
            path: "userstories",
            token: token,
            queryItems: [URLQueryItem(name: "assigned_to", value: "\(assigneeId)")],
            disablePagination: true
        )
    }

    public func fetchTasks(projectId: Int, token: AuthToken) async throws -> [Task] {
        try await authorizedGet(path: "tasks", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func fetchIssues(projectId: Int, token: AuthToken) async throws -> [Issue] {
        try await authorizedGet(path: "issues", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func fetchAssignedTasks(assigneeId: Int, token: AuthToken) async throws -> [Task] {
        try await authorizedGet(
            path: "tasks",
            token: token,
            queryItems: [URLQueryItem(name: "assigned_to", value: "\(assigneeId)")],
            disablePagination: true
        )
    }

    public func fetchAssignedIssues(assigneeId: Int, token: AuthToken) async throws -> [Issue] {
        try await authorizedGet(
            path: "issues",
            token: token,
            queryItems: [URLQueryItem(name: "assigned_to", value: "\(assigneeId)")],
            disablePagination: true
        )
    }

    public func fetchSprints(projectId: Int, token: AuthToken) async throws -> [Sprint] {
        try await authorizedGet(path: "milestones", token: token, queryItems: [URLQueryItem(name: "project", value: "\(projectId)")])
    }

    public func createUserStory(
        projectId: Int,
        subject: String,
        description: String?,
        tags: [String],
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?,
        attachments: [AttachmentUpload],
        token: AuthToken
    ) async throws -> UserStory {
        var body: [String: Any] = [
            "project": projectId,
            "subject": subject,
            "is_blocked": isBlocked
        ]
        if let description, !description.isEmpty {
            body["description"] = description
        }
        if !tags.isEmpty {
            body["tags"] = tags
        }
        if let assignedTo {
            body["assigned_to"] = assignedTo
        }
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        if let points {
            body["points"] = points
        }
        let story: UserStory = try await authorizedRequest(path: "userstories", method: "POST", body: body, token: token)
        for attachment in attachments {
            try await uploadAttachment(
                path: "userstories/attachments",
                projectId: projectId,
                objectId: story.id,
                attachment: attachment,
                token: token
            )
        }
        return story
    }

    public func updateUserStory(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        points: [String: Int]?,
        token: AuthToken
    ) async throws -> UserStory {
        var body: [String: Any] = ["subject": subject, "is_blocked": isBlocked]
        body["status"] = status as Any
        body["assigned_to"] = assignedTo as Any
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        if let points {
            body["points"] = points
        }
        return try await authorizedRequest(path: "userstories/\(id)", method: "PATCH", body: body, token: token)
    }

    public func createTask(
        projectId: Int,
        subject: String,
        userStoryId: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Task {
        var body: [String: Any] = [
            "project": projectId,
            "subject": subject,
            "is_blocked": isBlocked
        ]
        body["user_story"] = userStoryId as Any
        if let assignedTo {
            body["assigned_to"] = assignedTo
        }
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        return try await authorizedRequest(path: "tasks", method: "POST", body: body, token: token)
    }

    public func createIssue(
        projectId: Int,
        subject: String,
        description: String?,
        tags: [String],
        severity: Int?,
        priority: Int?,
        issueType: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        attachments: [AttachmentUpload],
        token: AuthToken
    ) async throws -> Issue {
        var body: [String: Any] = [
            "project": projectId,
            "subject": subject,
            "is_blocked": isBlocked
        ]
        if let description, !description.isEmpty {
            body["description"] = description
        }
        if !tags.isEmpty {
            body["tags"] = tags
        }
        if let severity {
            body["severity"] = severity
        }
        if let priority {
            body["priority"] = priority
        }
        if let issueType {
            body["type"] = issueType
        }
        if let assignedTo {
            body["assigned_to"] = assignedTo
        }
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        let issue: Issue = try await authorizedRequest(path: "issues", method: "POST", body: body, token: token)
        for attachment in attachments {
            try await uploadAttachment(
                path: "issues/attachments",
                projectId: projectId,
                objectId: issue.id,
                attachment: attachment,
                token: token
            )
        }
        return issue
    }

    public func updateTask(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Task {
        var body: [String: Any] = ["subject": subject, "is_blocked": isBlocked]
        body["status"] = status as Any
        body["assigned_to"] = assignedTo as Any
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        return try await authorizedRequest(path: "tasks/\(id)", method: "PATCH", body: body, token: token)
    }

    public func updateIssue(
        id: Int,
        subject: String,
        status: Int?,
        assignedTo: Int?,
        dueDate: String?,
        dueDateReason: String?,
        isBlocked: Bool,
        blockedNote: String?,
        token: AuthToken
    ) async throws -> Issue {
        var body: [String: Any] = ["subject": subject, "is_blocked": isBlocked]
        body["status"] = status as Any
        body["assigned_to"] = assignedTo as Any
        if let dueDate {
            body["due_date"] = dueDate
        }
        if let dueDateReason, !dueDateReason.isEmpty {
            body["due_date_reason"] = dueDateReason
        }
        if let blockedNote, !blockedNote.isEmpty {
            body["blocked_note"] = blockedNote
        }
        return try await authorizedRequest(path: "issues/\(id)", method: "PATCH", body: body, token: token)
    }

    public func deleteUserStory(id: Int, token: AuthToken) async throws {
        try await authorizedDelete(path: "userstories/\(id)", token: token)
    }

    public func deleteTask(id: Int, token: AuthToken) async throws {
        try await authorizedDelete(path: "tasks/\(id)", token: token)
    }

    public func deleteIssue(id: Int, token: AuthToken) async throws {
        try await authorizedDelete(path: "issues/\(id)", token: token)
    }

    public func refresh(refreshToken: String) async throws -> AuthToken {
        var request = URLRequest(url: baseURL.appending(path: "auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
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

    private func authorizedGet<T: Decodable>(path: String, token: AuthToken, queryItems: [URLQueryItem]? = nil, disablePagination: Bool = false) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        guard let url = components.url else { throw TaigaError.unknown }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        if disablePagination {
            request.setValue("true", forHTTPHeaderField: "x-disable-pagination")
        }

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

    private func authorizedRequest<T: Decodable>(path: String, method: String, body: [String: Any], token: AuthToken) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue("Bearer \(token.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = method
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

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

    private func authorizedDelete(path: String, token: AuthToken) async throws {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue("Bearer \(token.authToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        request.timeoutInterval = 20

        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TaigaError.unknown }
            guard 200..<300 ~= http.statusCode else {
                throw TaigaError.http(status: http.statusCode)
            }
        } catch let error as TaigaError {
            throw error
        } catch {
            throw TaigaError.network(underlying: error)
        }
    }

    private func uploadAttachment(
        path: String,
        projectId: Int,
        objectId: Int,
        attachment: AttachmentUpload,
        token: AuthToken
    ) async throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue("Bearer \(token.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let body = multipartBody(
            boundary: boundary,
            fields: [
                "project": "\(projectId)",
                "object_id": "\(objectId)"
            ],
            fileFieldName: "attached_file",
            fileName: attachment.fileName,
            mimeType: attachment.mimeType,
            fileData: attachment.data
        )

        do {
            let (data, response) = try await session.upload(for: request, from: body)
            guard let http = response as? HTTPURLResponse else { throw TaigaError.unknown }
            guard 200..<300 ~= http.statusCode else {
                _ = String(data: data, encoding: .utf8)
                throw TaigaError.http(status: http.statusCode)
            }
        } catch let error as TaigaError {
            throw error
        } catch {
            throw TaigaError.network(underlying: error)
        }
    }

    private func multipartBody(
        boundary: String,
        fields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var data = Data()
        let lineBreak = "\r\n"

        for (name, value) in fields {
            data.append("--\(boundary)\(lineBreak)")
            data.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)")
            data.append("\(value)\(lineBreak)")
        }

        data.append("--\(boundary)\(lineBreak)")
        data.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\(lineBreak)")
        data.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        data.append(fileData)
        data.append(lineBreak)
        data.append("--\(boundary)--\(lineBreak)")
        return data
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let value = string.data(using: .utf8) {
            append(value)
        }
    }
}
