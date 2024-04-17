import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.request(endpoint, completion: completion)
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.request(endpoint, type: type, completion: completion)
    }
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.fetchFile(url: url, completion: completion)
    }
}
