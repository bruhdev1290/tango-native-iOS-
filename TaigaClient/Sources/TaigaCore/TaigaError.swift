import Foundation

public enum TaigaError: Error, LocalizedError, Sendable {
    case invalidCredentials
    case http(status: Int)
    case decoding
    case network(underlying: Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password."
        case .http(let status):
            return "Server returned HTTP \(status)."
        case .decoding:
            return "Could not decode server response."
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .unknown:
            return "Unknown error"
        }
    }
}
