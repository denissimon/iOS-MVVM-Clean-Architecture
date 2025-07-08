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
    var validation: Bool
    var decoder: JSONDecoder?
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. If uploadTask is false, data task will be used.
    /// - Parameter validation: Whether to perform a validation based on the received status code
    /// - Parameter decoder: Customizable decoder for request<T: Decodable> method
    init(uploadTask: Bool = false, validation: Bool = true, decoder: JSONDecoder? = nil) {
        self.uploadTask = uploadTask
        self.validation = validation
        self.decoder = decoder
    }
}

protocol NetworkServiceAsyncAwaitType {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?) async throws -> (data: Data, response: URLResponse)
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?) async throws -> (decoded: T, response: URLResponse)
    func fetchFile(_ url: URL, configuration: RequestConfiguration?) async throws -> (data: Data?, response: URLResponse)
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?) async throws -> (result: Bool, response: URLResponse)
}

protocol NetworkServiceCallbacksType {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, configuration: RequestConfiguration?, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration?, completion: @escaping (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(_ url: URL, configuration: RequestConfiguration?, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration?, completion: @escaping (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable?
}

typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

class NetworkService: NetworkServiceType {
    
    let urlSession: URLSession
    var autoValidation: Bool
    
    let defaultConfiguration = RequestConfiguration()
    
    init(urlSession: URLSession = URLSession.shared, autoValidation: Bool = true) {
        self.urlSession = urlSession
        self.autoValidation = autoValidation
    }
    
    private func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
    
    @discardableResult
    private func validate(_ statusCode: Int?, requestValidation: Bool, data: Data? = nil) throws -> Bool {
        if !requestValidation { return true } // If validation is disabled for a given request (enabled by default), then this automatic validation will not be performed even if global validation is enabled
        if !autoValidation { return true } // Next, we check the global validation rule: when validation is enabled for a given request, but global validation is disabled, then this automatic validation will not be performed
        guard statusCode != nil, !(statusCode! >= 400 && statusCode! <= 599) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        return true
    }
    
    // MARK: - async/await API
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil) async throws -> (data: Data, response: URLResponse) {
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
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        return (data, response)
    }
    
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil) async throws -> (decoded: T, response: URLResponse) {
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
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        guard let decoded = try? (configuration?.decoder ?? JSONDecoder()).decode(type, from: data) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        
        return (decoded, response)
    }
    
    /// Fetches a file into memory
    func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil) async throws -> (data: Data?, response: URLResponse) {
        log("\nNetworkService fetchFile, url: \(url)")
        
        let (data, response) = try await urlSession.data(from: url)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        let requestValidation = configuration?.validation ?? defaultConfiguration.validation
        try validate(statusCode, requestValidation: requestValidation, data: data)
        
        guard !data.isEmpty else {
            return (nil, response)
        }
        
        return (data, response)
    }
    
    /// Downloads a file to disk. Supports background downloads.
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil) async throws -> (result: Bool, response: URLResponse) {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let (tempLocalUrl, response) = try await urlSession.download(from: url)
        
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
    
    func request(_ request: URLRequest, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
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
    
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
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
    
    /// Fetches a file into memory
    func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
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
    func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
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

extension URLSessionDataTask: NetworkCancellable {}
extension URLSessionDownloadTask: NetworkCancellable {}
