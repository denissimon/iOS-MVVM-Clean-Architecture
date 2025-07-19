import Foundation

protocol EndpointType: Sendable {
    var method: HTTPMethod { get }
    var baseURL: String { get }
    var path: String { get set }
    var params: HTTPParams? { get set }
}

final class Endpoint: EndpointType {
    let method: HTTPMethod
    let baseURL: String
    
    private let lock = NSLock()
    
    var path: String {
        get { lock.withLock { _path } }
        set { lock.withLock { _path = newValue } }
    }
    nonisolated(unsafe) private var _path: String
    
    var params: HTTPParams? {
        get { lock.withLock { _params } }
        set { lock.withLock { _params = newValue } }
    }
    nonisolated(unsafe) private var _params: HTTPParams?
    
    init(method: HTTPMethod, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self._path = path
        self._params = params
    }
}
