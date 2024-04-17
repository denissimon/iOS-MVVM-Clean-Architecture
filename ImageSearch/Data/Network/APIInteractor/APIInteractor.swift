import Foundation

protocol APIInteractor {
    @discardableResult
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    
    @discardableResult
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    
    @discardableResult
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
}

