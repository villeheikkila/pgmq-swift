import Foundation

public struct PGMQMessage: Sendable {
    let id: Int64
    let readCount: Int64
    let enqueuedAt: Date
    let vt: Date
    let payload: AnyJSON

    public init(id: Int64, readCount: Int64, enqueuedAt: Date, vt: Date, message: Data) throws {
        self.id = id
        self.readCount = readCount
        self.enqueuedAt = enqueuedAt
        self.vt = vt
        payload = try AnyJSON.from(message)
    }
}
