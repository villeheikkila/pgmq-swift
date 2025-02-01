import Foundation

public struct PGMQMessage: Sendable {
    public let id: Int64
    public let readCount: Int64
    public let enqueuedAt: Date
    public let vt: Date
    public let payload: AnyJSON

    public init(id: Int64, readCount: Int64, enqueuedAt: Date, vt: Date, message: Data) throws {
        self.id = id
        self.readCount = readCount
        self.enqueuedAt = enqueuedAt
        self.vt = vt
        payload = try AnyJSON.from(message)
    }
}
