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

struct RequestConfiguration {
    var uploadTask: Bool
    var autoValidation: Bool

    /// - Parameter uploadTask: To support uploading files, including background uploads. If uploadTask is false, data task will be used.
    init(uploadTask: Bool = false, autoValidation: Bool = true) {
        self.uploadTask = uploadTask
        self.autoValidation = autoValidation
    }
}

protocol NetworkServiceAsyncAwaitType: Sendable {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?) async throws -> (value: Data, statusCode: Int?)
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?) async throws -> (value: T, statusCode: Int?)
    func fetchFile(url: URL, configuration: RequestConfiguration?) async throws -> (value: Data?, statusCode: Int?)
    func downloadFile(url: URL, to localUrl: URL, configuration: RequestConfiguration?) async throws -> (value: Bool, statusCode: Int?)
}

protocol NetworkServiceCallbacksType: Sendable {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(value: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(value: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(value: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFile(url: URL, to localUrl: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(value: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
}

typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

final class NetworkService: NetworkServiceType {
    
    let urlSession: URLSession
    
    private let lock = NSLock()
    nonisolated(unsafe) var autoValidation: Bool {
        get { lock.withLock { _autoValidation } }
        set { lock.withLock { _autoValidation = newValue } }
    }
    nonisolated(unsafe) private var _autoValidation: Bool
    
    let defaultConfiguration = RequestConfiguration()
    
    init(urlSession: URLSession = URLSession.shared, autoValidation: Bool = true) {
        self.urlSession = urlSession
        self._autoValidation = autoValidation
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
    
    @discardableResult
    private func validate(_ statusCode: Int?, data: Data? = nil, requestValidation: Bool) throws -> Bool {
        if !requestValidation { return true } // If validation is disabled for a given request (by default is enabled), then this automatic validation will not occur, even if global validation is enabled
        if !_autoValidation { return true } // Next, we check the global validation rule: when validation is enabled for a given request, but global validation is disabled, then this automatic validation will not occur
        guard statusCode != nil, !(statusCode! >= 400 && statusCode! <= 599) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        return true
    }
    
    // MARK: - async/await API
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil) async throws -> (value: Data, statusCode: Int?) {
        let configUploadTask: Bool = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var msg = "\nNetworkService request \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var data = Data()
        var response = URLResponse()
        
        switch configUploadTask {
        case false:
            log(msg)
            (data, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (data, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: data, requestValidation: configAutoValidation)
        
        return (data, statusCode)
    }
    
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil) async throws -> (value: T, statusCode: Int?) {
        let configUploadTask: Bool = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var msg = "\nNetworkService request<T: Decodable> \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var data = Data()
        var response = URLResponse()
        
        switch configUploadTask {
        case false:
            log(msg)
            (data, response) = try await urlSession.data(
                for: request
            )
        case true:
            guard let httpBody = request.httpBody, ["POST", "PUT"].contains(request.httpMethod) else {
                throw NetworkError()
            }
            log(msg)
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (data, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: data, requestValidation: configAutoValidation)
        
        guard let decoded = try? JSONDecoder().decode(type, from: data) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        
        return (decoded, statusCode)
    }
    
    /// Fetches a file into memory
    func fetchFile(url: URL, configuration: RequestConfiguration? = nil) async throws -> (value: Data?, statusCode: Int?) {
        log("\nNetworkService fetchFile url: \(url)")
        
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        let (data, response) = try await urlSession.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: data, requestValidation: configAutoValidation)
        
        guard !data.isEmpty else {
            return (nil, statusCode)
        }
        
        return (data, statusCode)
    }
    
    /// Downloads a file to disk. Supports background downloads.
    func downloadFile(url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil) async throws -> (value: Bool, statusCode: Int?) {
        log("\nNetworkService downloadFile url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, requestValidation: configAutoValidation)
        
        if statusCode == 404 {
            throw NetworkError(statusCode: statusCode)
        }
        
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
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(value: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var msg = "\nNetworkService request \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        switch configUploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            let uploadTask = urlSession.uploadTask(with: updatedRequest, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil {
                    completion(.success((data, statusCode)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(value: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var msg = "\nNetworkService request<T: Decodable> \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        switch configUploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil {
                    guard let data = data, let decoded = try? JSONDecoder().decode(type, from: data) else {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            let uploadTask = urlSession.uploadTask(with: updatedRequest, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil {
                    guard let data = data, let decoded = try? JSONDecoder().decode(type, from: data) else {
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
    func fetchFile(url: URL, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(value: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService fetchFile url: \(url)")
        
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            guard error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil else {
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
    
    /// Downloads a file to disk. Supports background downloads.
    func downloadFile(url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(value: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService downloadFile url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = configuration?.autoValidation ?? defaultConfiguration.autoValidation
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let response = response as? HTTPURLResponse
            let statusCode = response?.statusCode
            
            guard let tempLocalUrl = tempLocalUrl, error == nil, statusCode != 404, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil else {
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
