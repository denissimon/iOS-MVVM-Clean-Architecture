import Foundation

protocol APIInteractor {
    func request(_ endpoint: EndpointType) async throws -> Data
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T
    func fetchFile(url: URL) async throws -> Data?
}
