import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    private func handleError(_ error: Error) -> AppError {
        if error is NetworkError {
            let networkError = error as! NetworkError
            if let statusCode = networkError.statusCode {
                if statusCode >= 400 && statusCode <= 599 {
                    return AppError.server(networkError.error, statusCode: statusCode, data: networkError.data)
                } else {
                    return AppError.unexpected(networkError.error, statusCode: statusCode, data: networkError.data)
                }
            }
        }
        return AppError.unexpected(error)
    }
    
    func request(_ endpoint: EndpointType) async throws -> Data {
        do {
            return try await urlSessionAdapter.request(endpoint)
        } catch {
            throw handleError(error)
        }
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T {
        do {
            return try await urlSessionAdapter.request(endpoint, type: type)
        } catch {
            throw handleError(error)
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
