import Foundation

public struct PGMQQueueMetrics: Sendable {
    let name: String
    let length: Int64
    let newestMsgAgeSec: Int64?
    let oldestMsgAgeSec: Int64?
    let totalMessages: Int64
    let scrapeTime: Date
}
