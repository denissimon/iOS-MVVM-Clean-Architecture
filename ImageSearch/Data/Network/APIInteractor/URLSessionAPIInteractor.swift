import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    private func handleError(_ error: Error? = nil) -> AppError {
        switch error {
        case nil:
            return AppError.default()
        default:
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
        }
        return AppError.unexpected(error)
    }
    
    func request(_ endpoint: EndpointType) async throws -> Data {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { throw handleError() }
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        do {
            return try await urlSessionAdapter.request(request)
        } catch {
            throw handleError(error)
        }
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { throw handleError() }
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        do {
            return try await urlSessionAdapter.request(request, type: type)
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
