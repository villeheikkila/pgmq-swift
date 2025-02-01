import Foundation
import PostgresNIO

public typealias JSONObject = [String: AnyJSONB]
public typealias JSONArray = [AnyJSONB]

public enum AnyJSONB: Sendable, Codable, Hashable {
    case null
    case bool(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
    case object(JSONObject)
    case array(JSONArray)

    public var value: Any {
        switch self {
        case .null: NSNull()
        case let .string(string): string
        case let .integer(val): val
        case let .double(val): val
        case let .object(dictionary): dictionary.mapValues(\.value)
        case let .array(array): array.map(\.value)
        case let .bool(bool): bool
        }
    }

    public var isNil: Bool {
        if case .null = self {
            return true
        }

        return false
    }

    public var boolValue: Bool? {
        if case let .bool(val) = self {
            return val
        }
        return nil
    }

    public var objectValue: JSONObject? {
        if case let .object(dictionary) = self {
            return dictionary
        }
        return nil
    }

    public var arrayValue: JSONArray? {
        if case let .array(array) = self {
            return array
        }
        return nil
    }

    public var stringValue: String? {
        if case let .string(string) = self {
            return string
        }
        return nil
    }

    public var intValue: Int? {
        if case let .integer(val) = self {
            return val
        }
        return nil
    }

    public var doubleValue: Double? {
        if case let .double(val) = self {
            return val
        }
        return nil
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let val = try? container.decode(Int.self) {
            self = .integer(val)
        } else if let val = try? container.decode(Double.self) {
            self = .double(val)
        } else if let val = try? container.decode(String.self) {
            self = .string(val)
        } else if let val = try? container.decode(Bool.self) {
            self = .bool(val)
        } else if let val = try? container.decode(JSONArray.self) {
            self = .array(val)
        } else if let val = try? container.decode(JSONObject.self) {
            self = .object(val)
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case let .array(val): try container.encode(val)
        case let .object(val): try container.encode(val)
        case let .string(val): try container.encode(val)
        case let .integer(val): try container.encode(val)
        case let .double(val): try container.encode(val)
        case let .bool(val): try container.encode(val)
        }
    }
}

extension AnyJSONB: ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) {
        self = .null
    }
}

extension AnyJSONB: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension AnyJSONB: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyJSONB...) {
        self = .array(elements)
    }
}

extension AnyJSONB: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .integer(value)
    }
}

extension AnyJSONB: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnyJSONB: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AnyJSONB: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyJSONB)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension AnyJSONB: CustomStringConvertible {
    public var description: String {
        String(describing: value)
    }
}

public extension AnyJSONB {
    static func from(_ data: Data) throws -> AnyJSONB {
        let decoder = JSONDecoder()
        return try decoder.decode(AnyJSONB.self, from: data)
    }
}

public extension AnyJSONB {
    subscript(key: String) -> AnyJSONB? {
        guard case let .object(dict) = self else {
            return nil
        }
        return dict[key]
    }

    subscript(index: Int) -> AnyJSONB? {
        guard case let .array(array) = self else {
            return nil
        }
        guard index >= 0, index < array.count else {
            return nil
        }
        return array[index]
    }
}

extension AnyJSONB: PostgresEncodable, PostgresDecodable {
    public static var psqlType: PostgresDataType {
        .jsonb
    }

    public func encode<JSONEncoder>(
        into byteBuffer: inout NIOCore.ByteBuffer,
        context: PostgresEncodingContext<JSONEncoder>
    ) throws where JSONEncoder: PostgresJSONEncoder {
        try context.jsonEncoder.encode(self, into: &byteBuffer)
    }

    public static func decode<JSONDecoder>(
        from buffer: NIOCore.ByteBuffer,
        context: PostgresDecodingContext<JSONDecoder>
    ) throws -> AnyJSONB where JSONDecoder: PostgresJSONDecoder {
        try context.jsonDecoder.decode(AnyJSONB.self, from: buffer)
    }
}
