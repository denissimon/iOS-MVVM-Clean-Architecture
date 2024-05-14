import Foundation

struct NetworkError: Error {
    let error: Error?
    let statusCode: Int?
    let data: Data?
    
    init(error: Error? = nil, statusCode: Int? = nil, data: Data? = nil) {
        self.error = error
        self.statusCode = statusCode
        self.data = data
    }
}

protocol NetworkServiceType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
    func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable?
    
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFileWithStatusCode(url: URL, completion: @escaping ((result: Data?, statusCode: Int?)) -> Void) -> NetworkCancellable?
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
}

class NetworkService: NetworkServiceType {
    
    let urlSession: URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
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
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                if error == nil {
                    completion(.success(data))
                    return
                }
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success(decoded))
                    return
                }
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success(decoded))
                    return
                }
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// Fetches a file into memory
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, _, error) in
            guard let data = data, !data.isEmpty, error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard let tempLocalUrl = tempLocalUrl, error == nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
                return
            }
            do {
                if !FileManager().fileExists(atPath: localUrl.path) {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                }
                completion(.success(true))
            } catch {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
            }
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool = false, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
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
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    completion(.success((data, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError()))
            return nil
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        switch uploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            dataTask.resume()
            return dataTask
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                completion(.failure(NetworkError()))
                return nil
            }
            log(msg)
            request.httpBody = nil
            
            let uploadTask = urlSession.uploadTask(with: request, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil {
                    guard let data = data, let decoded = ResponseDecodable.decode(type, data: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// Fetches a file into memory
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
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard let tempLocalUrl = tempLocalUrl, error == nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
                return
            }
            do {
                if !FileManager().fileExists(atPath: localUrl.path) {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                }
                completion(.success((true, statusCode)))
            } catch {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
            }
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
}

protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}
extension URLSessionDownloadTask: NetworkCancellable {}
