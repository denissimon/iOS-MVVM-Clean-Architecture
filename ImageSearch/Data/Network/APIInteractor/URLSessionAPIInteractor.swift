import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    func request(_ endpoint: EndpointType) async throws -> Data {
        do {
            return try await urlSessionAdapter.request(endpoint)
        } catch {
            throw NetworkError(error: error)
        }
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T {
        do {
            return try await urlSessionAdapter.request(endpoint, type: type)
        } catch {
            throw NetworkError(error: error)
        }
    }
    
    func fetchFile(url: URL) async throws -> Data? {
        do {
            return try await urlSessionAdapter.fetchFile(url: url)
        } catch {
            return nil
        }
    }
}
