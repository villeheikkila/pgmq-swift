import Foundation

public enum PGMQError: Error, LocalizedError {
    case noMessageID
    case queueNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .noMessageID:
            return "Failed to retrieve message ID after sending"
        case let .queueNotFound(name):
            return "Queue '\(name)' not found"
        }
    }
}
