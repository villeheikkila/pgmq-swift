import Foundation
import PostgresNIO

public protocol PGMQ: Sendable {
    func send(queue: String, message: PostgresEncodable, delay: Int) async throws -> Int64
    func send(queue: String, messages: PostgresArrayEncodable, delay: Int) async throws -> [Int64]
    func read(queue: String, vt: Int) async throws -> PGMQMessage?
    func read(queue: String, vt: Int, qty: Int) async throws -> [PGMQMessage]
    func archive(queue: String, id: Int64) async throws -> Bool
    func archive(queue: String, ids: [Int64]) async throws -> [Int64]
    func delete(queue: String, id: Int64) async throws -> Bool
    func delete(queue: String, ids: [Int64]) async throws -> [Int64]
    func purgeQueue(queue: String) async throws -> Int64
    func pop(queue: String) async throws -> PGMQMessage?
    func setVt(queue: String, id: Int64, vt: Int) async throws -> PGMQMessage?
    func metrics(queue: String) async throws -> PGMQQueueMetrics
    func createQueue(queue: String) async throws
    func dropQueue(queue: String) async throws
    func createUnloggedQueue(queue: String) async throws
    func createPartitionedQueue(queue: String, partitionInterval: String, retentionInterval: String) async throws
    func metricsAll() async throws -> [PGMQQueueMetrics]
    func detachArchive(queue: String) async throws
}

public final class PGMQClient: PGMQ, Sendable {
    private let client: PostgresClient

    public init(client: PostgresClient) {
        self.client = client
    }

    @discardableResult
    public func send(queue: String, message: PostgresEncodable, delay: Int = 0) async throws -> Int64 {
        let rows = try await client.query("SELECT * FROM pgmq.send(\(queue), \(message), \(delay))")
        for try await (id) in rows.decode(Int64.self) {
            return id
        }
        throw PGMQError.noMessageID
    }

    @discardableResult
    public func send(queue: String, messages: PostgresArrayEncodable, delay: Int = 0) async throws
        -> [Int64]
    {
        let rows = try await client.query("SELECT * FROM pgmq.send_batch(\(queue), \(messages), \(delay))")
        var ids: [Int64] = []
        for try await (id) in rows.decode(Int64.self) {
            ids.append(id)
        }
        return ids
    }

    public func read(queue: String, vt: Int = 30) async throws -> PGMQMessage? {
        let rows = try await client.query("SELECT * FROM pgmq.read(\(queue), \(vt), 1)")
        for try await (id, readCount, enqueuedAt, vt, message) in rows.decode(
            (Int64, Int64, Date, Date, AnyJSONB).self
        ) {
            return try PGMQMessage(
                id: id,
                readCount: readCount,
                enqueuedAt: enqueuedAt,
                vt: vt,
                message: message
            )
        }
        return nil
    }

    public func read(queue: String, vt: Int = 30, qty: Int) async throws -> [PGMQMessage] {
        let rows = try await client.query("SELECT * FROM pgmq.read(\(queue), \(vt), \(qty))")
        var messages: [PGMQMessage] = []
        for try await (id, readCount, enqueuedAt, vt, message) in rows.decode(
            (Int64, Int64, Date, Date, AnyJSONB).self
        ) {
            try messages.append(
                PGMQMessage(
                    id: id,
                    readCount: readCount,
                    enqueuedAt: enqueuedAt,
                    vt: vt,
                    message: message
                ))
        }
        return messages
    }

    public func archive(queue: String, id: Int64) async throws -> Bool {
        let rows = try await client.query("SELECT pgmq.archive(\(queue), \(id))")
        for try await (archived) in rows.decode(Bool.self) {
            return archived
        }
        return false
    }

    public func archive(queue: String, ids: [Int64]) async throws -> [Int64] {
        let rows = try await client.query("SELECT pgmq.archive(\(queue), \(ids))")
        var archived: [Int64] = []
        for try await (id) in rows.decode(Int64.self) {
            archived.append(id)
        }
        return archived
    }

    @discardableResult
    public func delete(queue: String, id: Int64) async throws -> Bool {
        let rows = try await client.query("SELECT pgmq.delete(\(queue), \(id))")
        for try await (deleted) in rows.decode(Bool.self) {
            return deleted
        }
        return false
    }

    @discardableResult
    public func delete(queue: String, ids: [Int64]) async throws -> [Int64] {
        let rows = try await client.query("SELECT pgmq.delete(\(queue), \(ids))")
        var deleted: [Int64] = []
        for try await (id) in rows.decode(Int64.self) {
            deleted.append(id)
        }
        return deleted
    }

    public func purgeQueue(queue: String) async throws -> Int64 {
        let rows = try await client.query("SELECT pgmq.purge_queue(\(queue))")
        for try await (count) in rows.decode(Int64.self) {
            return count
        }
        throw PGMQError.queueNotFound(queue)
    }

    public func pop(queue: String) async throws -> PGMQMessage? {
        let rows = try await client.query("SELECT * FROM pgmq.pop(\(queue))")
        for try await (id, readCount, enqueuedAt, vt, message) in rows.decode(
            (Int64, Int64, Date, Date, AnyJSONB).self
        ) {
            return try PGMQMessage(
                id: id,
                readCount: readCount,
                enqueuedAt: enqueuedAt,
                vt: vt,
                message: message
            )
        }
        return nil
    }

    @discardableResult
    public func setVt(queue: String, id: Int64, vt: Int) async throws -> PGMQMessage? {
        let rows = try await client.query("SELECT * FROM pgmq.set_vt(\(queue), \(id), \(vt))")
        for try await (id, readCount, enqueuedAt, vt, message) in rows.decode(
            (Int64, Int64, Date, Date, AnyJSONB).self
        ) {
            return try PGMQMessage(
                id: id,
                readCount: readCount,
                enqueuedAt: enqueuedAt,
                vt: vt,
                message: message
            )
        }
        return nil
    }

    public func metrics(queue: String) async throws -> PGMQQueueMetrics {
        let rows = try await client.query("SELECT * FROM pgmq.metrics(\(queue))")
        for try await (
            queueName,
            queueLength,
            newestMsgAgeSec,
            oldestMsgAgeSec,
            totalMessages,
            scrapeTime
        ) in rows.decode((String, Int64, Int64?, Int64?, Int64, Date).self) {
            return PGMQQueueMetrics(
                name: queueName,
                length: queueLength,
                newestMsgAgeSec: newestMsgAgeSec,
                oldestMsgAgeSec: oldestMsgAgeSec,
                totalMessages: totalMessages,
                scrapeTime: scrapeTime
            )
        }
        throw PGMQError.queueNotFound(queue)
    }

    public func createQueue(queue: String) async throws {
        try await client.query("SELECT pgmq.create(\(queue))")
    }

    public func dropQueue(queue: String) async throws {
        try await client.query("SELECT pgmq.drop_queue(\(queue))")
    }

    public func createUnloggedQueue(queue: String) async throws {
        try await client.query("SELECT pgmq.create_unlogged(\(queue))")
    }

    public func createPartitionedQueue(queue: String, partitionInterval: String, retentionInterval: String) async throws {
        try await client.query("SELECT pgmq.create_partitioned(\(queue), \(partitionInterval), \(retentionInterval))")
    }

    public func metricsAll() async throws -> [PGMQQueueMetrics] {
        let rows = try await client.query("SELECT * FROM pgmq.metrics_all()")
        var metrics: [PGMQQueueMetrics] = []
        for try await (
            queueName,
            queueLength,
            newestMsgAgeSec,
            oldestMsgAgeSec,
            totalMessages,
            scrapeTime
        ) in rows.decode((String, String, String?, String?, String, String).self) {
            metrics.append(
                PGMQQueueMetrics(
                    name: queueName,
                    length: Int64(queueLength) ?? 0,
                    newestMsgAgeSec: newestMsgAgeSec.flatMap { Int64($0) },
                    oldestMsgAgeSec: oldestMsgAgeSec.flatMap { Int64($0) },
                    totalMessages: Int64(totalMessages) ?? 0,
                    scrapeTime: ISO8601DateFormatter().date(from: scrapeTime) ?? Date()
                ))
        }
        return metrics
    }

    public func detachArchive(queue: String) async throws {
        try await client.query("SELECT pgmq.detach_archive(\(queue))")
    }
}
