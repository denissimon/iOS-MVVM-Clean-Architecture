import Foundation

final class URLSessionAPIInteractor: APIInteractor {
    
    private let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    private func customError(_ error: Error? = nil) -> CustomError {
        switch error {
        case nil:
            return CustomError.app(.apiClient)
        case let error as NetworkError:
            guard let statusCode = error.statusCode else { break }
            if statusCode >= 300 && statusCode <= 599 {
                return CustomError.server(error.error, statusCode: statusCode, data: error.data)
            }
        default:
            guard let nsError = error as NSError?, nsError.domain == NSURLErrorDomain else { break }
            if NetworkError.connectionErrors.contains(nsError.code) {
                return CustomError.internetConnection(error)
            }
        }
        return CustomError.unexpected(error)
    }
    
    func request(_ endpoint: EndpointType) async throws -> Data {
        guard let request = RequestFactory.request(endpoint) else { throw customError() }
        do {
            return try await urlSessionAdapter.request(request).data
        } catch {
            throw customError(error)
        }
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type) async throws -> T {
        guard let request = RequestFactory.request(endpoint) else { throw customError() }
        do {
            return try await urlSessionAdapter.request(request, type: type).decoded
        } catch {
            throw customError(error)
        }
    }
    
    func fetchFile(_ url: URL) async throws -> Data? {
        do {
            return try await urlSessionAdapter.fetchFile(url).data
        } catch {
            return nil
        }
    }
}
