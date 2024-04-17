import Foundation

struct NetworkError: Error {
    let error: Error?
    let statusCode: Int?
    let data: Data?
}

protocol NetworkServiceType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
    
    func requestWithStatusCode(_ endpoint: EndpointType, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable?
}

class NetworkService: NetworkServiceType {
       
    let urlSession: URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService request \(endpoint.method.rawValue), url: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            if error == nil {
                completion(.success(data))
                return
            }
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService request<T: Decodable> \(endpoint.method.rawValue), url: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            if error == nil {
                guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                    completion(.failure(NetworkError(error: nil, statusCode: statusCode, data: data)))
                    return
                }
                completion(.success(decoded))
                return
            }
            
            completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
        }

        dataTask.resume()
        
        return dataTask
    }
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(url)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            guard let data = data, !data.isEmpty, error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    func requestWithStatusCode(_ endpoint: EndpointType, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestWithStatusCode \(endpoint.method.rawValue), url: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            if error == nil {
                completion(.success((data, statusCode)))
                return
            }
            
            completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, statusCode: nil, data: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestWithStatusCode<T: Decodable> \(endpoint.method.rawValue), url: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            if error == nil {
                guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                    completion(.failure(NetworkError(error: nil, statusCode: statusCode, data: data)))
                    return
                }
                completion(.success((decoded, statusCode)))
                return
            }
            
            completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
        }

        dataTask.resume()
        
        return dataTask
    }
    
    func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            guard let data = data, !data.isEmpty, error == nil else {
                completion((nil, statusCode))
                return
            }
            
            completion((data, statusCode))
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
}

protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}

