import Foundation

// Result<Type, CustomError> can be used as another way to return the result

protocol APIInteractor {
    func request(_ endpoint: EndpointType) async throws -> Data
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T
    func fetchFile(url: URL) async throws -> Data?
}
