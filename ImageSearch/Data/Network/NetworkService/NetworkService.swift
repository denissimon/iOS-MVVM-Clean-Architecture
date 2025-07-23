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

struct RequestConfiguration: Sendable {
    var uploadTask: Bool
    var validation: Bool
    var decoder: JSONDecoder?
    
    /// - Parameter uploadTask: Set to `true` to use upload task instead of data task. Supports background uploads. Defaults to `false`.
    /// - Parameter validation: Whether to perform a validation based on the received status code. Defaults to `true`.
    /// - Parameter decoder: The customizable decoder used in `request<T: Decodable>` methods.
    init(uploadTask: Bool = false, validation: Bool = true, decoder: JSONDecoder? = nil) {
        self.uploadTask = uploadTask
        self.validation = validation
        self.decoder = decoder
    }
}

protocol NetworkServiceAsyncAwaitType: Sendable {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?, delegate: URLSessionTaskDelegate?) async throws -> (data: Data, response: URLResponse)
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, delegate: URLSessionTaskDelegate?) async throws -> (decoded: T, response: URLResponse)
    func fetchFile(_ url: URL, configuration: RequestConfiguration?, delegate: URLSessionTaskDelegate?) async throws -> (data: Data?, response: URLResponse)
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, delegate: URLSessionTaskDelegate?) async throws -> (result: Bool, response: URLResponse)
}

protocol NetworkServiceCallbacksType: Sendable {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(_ url: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, completion: @escaping @Sendable (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
}

typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

final class NetworkService: NetworkServiceType {
    
    let urlSession: URLSession
    
    private let lock = NSLock()
    
    var autoValidation: Bool {
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
    
    private func validate(_ statusCode: Int?, requestValidation: Bool, data: Data? = nil) throws {
        /// If validation is disabled for a given request, then this validation will not be performed even if global validation (`autoValidation` property) is enabled
        if requestValidation == false { return }
        
        /// When validation is enabled for a given request, but global validation is disabled, then this validation will not be performed
        if _autoValidation == false { return }
        
        guard statusCode != nil, !(statusCode! >= 300 && statusCode! <= 599) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
    }
    
    // MARK: - async/await API
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil, delegate: URLSessionTaskDelegate? = nil) async throws -> (data: Data, response: URLResponse) {
        let isUploadTask = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        
        var msg = "\nNetworkService request \(request.httpMethod ?? "")"
        if isUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var data = Data()
        var response = URLResponse()
        
        switch isUploadTask {
        case false:
            log(msg)
            (data, response) = try await urlSession.data(
                for: request,
                delegate: delegate
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
                from: httpBody,
                delegate: delegate
            )
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        return (data, response)
    }
    
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil, delegate: URLSessionTaskDelegate? = nil) async throws -> (decoded: T, response: URLResponse) {
        let isUploadTask = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        
        var msg = "\nNetworkService request<T: Decodable> \(request.httpMethod ?? "")"
        if isUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var data = Data()
        var response = URLResponse()
        
        switch isUploadTask {
        case false:
            log(msg)
            (data, response) = try await urlSession.data(
                for: request,
                delegate: delegate
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
                from: httpBody,
                delegate: delegate
            )
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        guard let decoded = try? (configuration?.decoder ?? JSONDecoder()).decode(type, from: data) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        
        return (decoded, response)
    }
    
    /// Fetches a file into memory.
    func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil, delegate: URLSessionTaskDelegate? = nil) async throws -> (data: Data?, response: URLResponse) {
        log("\nNetworkService fetchFile, url: \(url)")
        
        let (data, response) = try await urlSession.data(
            from: url,
            delegate: delegate
        )
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        guard !data.isEmpty else {
            return (nil, response)
        }
        
        return (data, response)
    }
    
    /// Downloads a file to disk. Supports background downloads.
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil, delegate: URLSessionTaskDelegate? = nil) async throws -> (result: Bool, response: URLResponse) {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(
            from: url,
            delegate: delegate
        )
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation)
        
        if statusCode == 404 {
            throw NetworkError(statusCode: statusCode)
        }
        
        do {
            if !FileManager().fileExists(atPath: localUrl.path) {
                try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
            }
            return (true, response)
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    // MARK: - callbacks API
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
        let isUploadTask = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        
        var msg = "\nNetworkService request \(request.httpMethod ?? "")"
        if isUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        switch isUploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: requestValidation, data: data)) != nil {
                    completion(.success((data, response)))
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
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: requestValidation, data: data)) != nil {
                    completion(.success((data, response)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    public func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
        let isUploadTask = configuration?.uploadTask ?? defaultConfiguration.uploadTask
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        
        var msg = "\nNetworkService request<T: Decodable> \(request.httpMethod ?? "")"
        if isUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        switch isUploadTask {
        case false:
            log(msg)
            let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: requestValidation, data: data)) != nil {
                    guard let data = data,
                          let decoded = try? (configuration?.decoder ?? JSONDecoder()).decode(type, from: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, response)))
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
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                
                if error == nil, (try? self.validate(statusCode, requestValidation: requestValidation, data: data)) != nil {
                    guard let data = data,
                          let decoded = try? (configuration?.decoder ?? JSONDecoder()).decode(type, from: data) else {
                        completion(.failure(NetworkError(statusCode: statusCode, data: data)))
                        return
                    }
                    completion(.success((decoded, response)))
                    return
                }
                
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
            }
            
            uploadTask.resume()
            return uploadTask
        }
    }
    
    /// Fetches a file into memory.
    func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService fetchFile, url: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let requestValidation = configuration?.validation ?? self.defaultConfiguration.validation
            
            guard error == nil, (try? self.validate(statusCode, requestValidation: requestValidation, data: data)) != nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode, data: data)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.success((nil, response)))
                return
            }
            
            completion(.success((data, response)))
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    /// Downloads a file to disk. Supports background downloads.
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil, completion: @escaping @Sendable (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let downloadTask = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            let requestValidation = configuration?.validation ?? self.defaultConfiguration.validation
            
            guard let tempLocalUrl = tempLocalUrl, error == nil, statusCode != 404, (try? self.validate(statusCode, requestValidation: requestValidation)) != nil else {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
                return
            }
            
            do {
                if !FileManager().fileExists(atPath: localUrl.path) {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                }
                completion(.success((true, response)))
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

extension URLSessionTask: NetworkCancellable {}
