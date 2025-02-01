import Foundation

public struct PGMQQueueMetrics: Sendable {
    public let name: String
    public let length: Int64
    public let newestMsgAgeSec: Int64?
    public let oldestMsgAgeSec: Int64?
    public let totalMessages: Int64
    public let scrapeTime: Date
}
