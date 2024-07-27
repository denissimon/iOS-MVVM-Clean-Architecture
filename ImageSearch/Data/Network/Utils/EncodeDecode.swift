import Foundation

struct RequestEncodable {
    static func encode<T: Encodable>(_ value: T) -> Data?  {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(value)
            return data
        } catch _ {
            return nil
        }
    }
}

extension Encodable {
    func encode() -> Data? { RequestEncodable.encode(self) }
}

struct ResponseDecodable {
    static func decode<T: Decodable>(_ type: T.Type, data: Data) -> T? {
        let jsonDecoder = JSONDecoder()
        do {
            let response = try jsonDecoder.decode(T.self, from: data)
            return response
        } catch _ {
            return nil
        }
    }
}
