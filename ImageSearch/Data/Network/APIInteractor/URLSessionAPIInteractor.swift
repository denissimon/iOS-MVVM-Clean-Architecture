import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    private func customError(_ error: Error? = nil) -> CustomError {
        switch error {
        case nil:
            return CustomError.app(.apiClient)
        default:
            if error is NetworkError {
                let networkError = error as! NetworkError
                if let statusCode = networkError.statusCode {
                    if statusCode >= 400 && statusCode <= 599 {
                        return CustomError.server(networkError.error, statusCode: statusCode, data: networkError.data)
                    } else {
                        return CustomError.internetConnection(networkError.error, statusCode: statusCode, data: networkError.data)
                    }
                }
            }
            return CustomError.internetConnection(error)
        }
    }
    
    func request(_ endpoint: EndpointType) async throws -> Data {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { throw customError() }
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        do {
            return try await urlSessionAdapter.request(request)
        } catch {
            throw customError(error)
        }
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { throw customError() }
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        do {
            return try await urlSessionAdapter.request(request, type: type)
        } catch {
            throw customError(error)
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
