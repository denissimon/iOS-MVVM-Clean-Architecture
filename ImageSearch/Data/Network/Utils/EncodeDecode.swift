import Foundation

struct RequestEncodable {
    static func encode<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) -> Data? {
        let jsonEncoder = encoder ?? JSONEncoder()
        do {
            return try jsonEncoder.encode(value)
        } catch {
            return nil
        }
    }
}

extension Encodable {
    func encode() -> Data? { RequestEncodable.encode(self) }
}

struct ResponseDecodable {
    static func decode<T: Decodable>(_ type: T.Type, from data: Data, decoder: JSONDecoder? = nil) -> T? {
        let jsonDecoder = decoder ?? JSONDecoder()
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
