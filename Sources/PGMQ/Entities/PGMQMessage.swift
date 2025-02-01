import Foundation

public struct PGMQMessage: Sendable, Identifiable {
    public let id: Int64
    public let readCount: Int64
    public let enqueuedAt: Date
    public let vt: Date
    public let message: AnyJSONB

    public init(id: Int64, readCount: Int64, enqueuedAt: Date, vt: Date, message: AnyJSONB) throws {
        self.id = id
        self.readCount = readCount
        self.enqueuedAt = enqueuedAt
        self.vt = vt
        self.message = message
    }
}
