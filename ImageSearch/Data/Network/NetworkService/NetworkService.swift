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

protocol NetworkServiceAsyncAwaitType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, uploadTask: Bool) async throws -> Data
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool) async throws -> T
    func fetchFile(url: URL) async throws -> Data?
    func downloadFile(url: URL, to localUrl: URL) async throws -> Bool
    
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool) async throws -> (result: Data, statusCode: Int?)
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool) async throws -> (result: T, statusCode: Int?)
    func fetchFileWithStatusCode(url: URL) async throws -> (result: Data?, statusCode: Int?)
    func downloadFileWithStatusCode(url: URL, to localUrl: URL) async throws -> (result: Bool, statusCode: Int?)
}

protocol NetworkServiceCallbacksType {
    var urlSession: URLSession { get }
    
    func request(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFile(url: URL, to localUrl: URL, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable?
    
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFileWithStatusCode(url: URL, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
}

typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

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
    
    @discardableResult
    private func checkStatusCode(_ statusCode: Int?, data: Data? = nil) throws -> Bool {
        guard statusCode != nil, !(statusCode! >= 400 && statusCode! <= 599) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        return true
    }
    
    // MARK: - async/await API
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request(_ endpoint: EndpointType, uploadTask: Bool = false) async throws -> Data {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch uploadTask {
        case false:
            log(msg)
            (responseData, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        try checkStatusCode(httpResponse?.statusCode, data: responseData)
        
        return responseData
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false) async throws -> T {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService request<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch uploadTask {
        case false:
            log(msg)
            (responseData, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode, data: responseData)
        
        guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
            throw NetworkError(statusCode: statusCode, data: responseData)
        }
        
        return decoded
    }
    
    /// Fetches a file into memory
    func fetchFile(url: URL) async throws -> Data? {
        log("\nNetworkService fetchFile: \(url)")
        
        let (responseData, response) = try await urlSession.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        try checkStatusCode(httpResponse?.statusCode, data: responseData)
        
        guard !responseData.isEmpty else {
            return nil
        }
        return responseData
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFile(url: URL, to localUrl: URL) async throws -> Bool {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode)
        
        do {
            if !FileManager().fileExists(atPath: localUrl.path) {
                try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
            }
            return true
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode(_ endpoint: EndpointType, uploadTask: Bool = false) async throws -> (result: Data, statusCode: Int?) {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch uploadTask {
        case false:
            log(msg)
            (responseData, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode, data: responseData)
        
        return (responseData, statusCode)
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode<T: Decodable>(_ endpoint: EndpointType, type: T.Type, uploadTask: Bool = false) async throws -> (result: T, statusCode: Int?) {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw NetworkError()
        }
        
        var request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(endpoint.method.rawValue)"
        if uploadTask { msg += ", uploadTask"}
        msg += ", url: \(url)"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch uploadTask {
        case false:
            log(msg)
            (responseData, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            request.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: request,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode, data: responseData)
        
        guard let decoded = ResponseDecodable.decode(type, data: responseData) else {
            throw NetworkError(statusCode: statusCode, data: responseData)
        }
        
        return (decoded, statusCode)
    }
    
    /// Fetches a file into memory
    func fetchFileWithStatusCode(url: URL) async throws -> (result: Data?, statusCode: Int?) {
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
        
        let (responseData, response) = try await urlSession.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode, data: responseData)
        
        guard !responseData.isEmpty else {
            return (nil, statusCode)
        }
        
        return (responseData, statusCode)
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFileWithStatusCode(url: URL, to localUrl: URL) async throws -> (result: Bool, statusCode: Int?) {
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try checkStatusCode(statusCode)
        
        do {
            if !FileManager().fileExists(atPath: localUrl.path) {
                try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
            }
            return (true, statusCode)
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    // MARK: - callbacks API
    
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
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
                    completion(.success(data))
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
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
                    completion(.success(data))
                    return
                }
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
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
    func fetchFile(url: URL, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(url)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard error == nil, (try? self.checkStatusCode(statusCode)) != nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.success(nil))
                return
            }
            completion(.success(data))
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
            
            guard let tempLocalUrl = tempLocalUrl, error == nil, (try? self.checkStatusCode(statusCode)) != nil else {
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
                
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
                
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
                
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
                
                if error == nil, (try? self.checkStatusCode(statusCode)) != nil {
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
    func fetchFileWithStatusCode(url: URL, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard error == nil, (try? self.checkStatusCode(statusCode)) != nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
                return
            }
            guard let data = data, !data.isEmpty else {
                completion(.success((nil, statusCode)))
                return
            }
            completion(.success((data, statusCode)))
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
            
            guard let tempLocalUrl = tempLocalUrl, error == nil, (try? self.checkStatusCode(statusCode)) != nil else {
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
