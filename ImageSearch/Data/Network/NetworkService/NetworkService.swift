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

struct RequestConfig {
    var uploadTask: Bool?
    var autoValidation: Bool?
    
    init(uploadTask: Bool? = nil, autoValidation: Bool? = nil) {
        self.uploadTask = uploadTask
        self.autoValidation = autoValidation
    }
}

protocol NetworkServiceAsyncAwaitType {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, config: RequestConfig?) async throws -> Data
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig?) async throws -> T
    func fetchFile(url: URL, config: RequestConfig?) async throws -> Data?
    func downloadFile(url: URL, to localUrl: URL, config: RequestConfig?) async throws -> Bool
    
    func requestWithStatusCode(_ request: URLRequest, config: RequestConfig?) async throws -> (result: Data, statusCode: Int?)
    func requestWithStatusCode<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig?) async throws -> (result: T, statusCode: Int?)
    func fetchFileWithStatusCode(url: URL, config: RequestConfig?) async throws -> (result: Data?, statusCode: Int?)
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, config: RequestConfig?) async throws -> (result: Bool, statusCode: Int?)
}

protocol NetworkServiceCallbacksType {
    var urlSession: URLSession { get }
    
    func request(_ request: URLRequest, config: RequestConfig?, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig?, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFile(url: URL, config: RequestConfig?, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFile(url: URL, to localUrl: URL, config: RequestConfig?, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable?
    
    func requestWithStatusCode(_ request: URLRequest, config: RequestConfig?, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func requestWithStatusCode<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig?, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func fetchFileWithStatusCode(url: URL, config: RequestConfig?, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, config: RequestConfig?, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable?
}

typealias NetworkServiceType = NetworkServiceAsyncAwaitType & NetworkServiceCallbacksType

class NetworkService: NetworkServiceType {
    
    let urlSession: URLSession
    var autoValidation: Bool
    private let defaultConfig = RequestConfig(uploadTask: false, autoValidation: true)
    
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
    private func validate(_ statusCode: Int?, data: Data? = nil, requestValidation: Bool) throws -> Bool {
        if !requestValidation { return true } // If validation is disabled for a given request (by default is enabled), then this automatic validation will not occur, even if global validation is enabled
        if !autoValidation { return true } // Next, we check the global validation rule: when validation is enabled for a given request (this is by default), but global validation is disabled, then this automatic validation will not occur
        guard statusCode != nil, !(statusCode! >= 400 && statusCode! <= 599) else {
            throw NetworkError(statusCode: statusCode, data: data)
        }
        return true
    }
    
    // MARK: - async/await API
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request(_ request: URLRequest, config: RequestConfig? = nil) async throws -> Data {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService request \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch configUploadTask {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        try validate(httpResponse?.statusCode, data: responseData, requestValidation: configAutoValidation)
        
        return responseData
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig? = nil) async throws -> T {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService request<T: Decodable> \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch configUploadTask {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: responseData, requestValidation: configAutoValidation)
        
        guard let decoded = try? JSONDecoder().decode(type, from: responseData) else {
            throw NetworkError(statusCode: statusCode, data: responseData)
        }
        
        return decoded
    }
    
    /// Fetches a file into memory
    func fetchFile(url: URL, config: RequestConfig? = nil) async throws -> Data? {
        log("\nNetworkService fetchFile: \(url)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        let (responseData, response) = try await urlSession.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        try validate(httpResponse?.statusCode, data: responseData, requestValidation: configAutoValidation)
        
        guard !responseData.isEmpty else {
            return nil
        }
        return responseData
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFile(url: URL, to localUrl: URL, config: RequestConfig? = nil) async throws -> Bool {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
            return true
        } catch {
            throw NetworkError(statusCode: statusCode)
        }
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode(_ request: URLRequest, config: RequestConfig? = nil) async throws -> (result: Data, statusCode: Int?) {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService requestWithStatusCode \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch configUploadTask {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: responseData, requestValidation: configAutoValidation)
        
        return (responseData, statusCode)
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig? = nil) async throws -> (result: T, statusCode: Int?) {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(request.httpMethod ?? "")"
        if configUploadTask { msg += ", uploadTask"}
        msg += ", url: \(request.url?.description ?? "")"
        
        var responseData = Data()
        var response = URLResponse()
        
        switch configUploadTask {
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            (responseData, response) = try await urlSession.upload(
                for: updatedRequest,
                from: httpBody
            )
        }
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: responseData, requestValidation: configAutoValidation)
        
        guard let decoded = try? JSONDecoder().decode(type, from: responseData) else {
            throw NetworkError(statusCode: statusCode, data: responseData)
        }
        
        return (decoded, statusCode)
    }
    
    /// Fetches a file into memory
    func fetchFileWithStatusCode(url: URL, config: RequestConfig? = nil) async throws -> (result: Data?, statusCode: Int?) {
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        let (responseData, response) = try await urlSession.data(from: url)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        try validate(statusCode, data: responseData, requestValidation: configAutoValidation)
        
        guard !responseData.isEmpty else {
            return (nil, statusCode)
        }
        
        return (responseData, statusCode)
    }
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns: .success(true), if successful
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, config: RequestConfig? = nil) async throws -> (result: Bool, statusCode: Int?) {
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func request(_ request: URLRequest, config: RequestConfig? = nil, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
            var updatedRequest = request
            updatedRequest.httpBody = nil
            let uploadTask = urlSession.uploadTask(with: updatedRequest, from: httpBody) { (data, response, error) in
                let response = response as? HTTPURLResponse
                let statusCode = response?.statusCode
                if error == nil, (try? self.validate(statusCode, requestValidation: configAutoValidation)) != nil {
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
    func request<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig? = nil, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
    func fetchFile(url: URL, config: RequestConfig? = nil, completion: @escaping (Result<Data?, NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService fetchFile: \(url)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
    func downloadFile(url: URL, to localUrl: URL, config: RequestConfig? = nil, completion: @escaping (Result<Bool, NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService downloadFile, url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
                completion(.success(true))
            } catch {
                completion(.failure(NetworkError(error: error, statusCode: statusCode)))
            }
        }
        
        downloadTask.resume()
        
        return downloadTask
    }
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode(_ request: URLRequest, config: RequestConfig? = nil, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService requestWithStatusCode \(request.httpMethod ?? "")"
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
    
    /// - Parameter uploadTask: To support uploading files, including background uploads. In other POST/PUT cases (e.g. with a json as httpBody), uploadTask can be false and dataTask will be used.
    func requestWithStatusCode<T: Decodable>(_ request: URLRequest, type: T.Type, config: RequestConfig? = nil, completion: @escaping (Result<(result: T, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        let configUploadTask: Bool = config?.uploadTask ?? defaultConfig.uploadTask!
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
        var msg = "\nNetworkService requestWithStatusCode<T: Decodable> \(request.httpMethod ?? "")"
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
    func fetchFileWithStatusCode(url: URL, config: RequestConfig? = nil, completion: @escaping (Result<(result: Data?, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService fetchFileWithStatusCode: \(url)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
    
    /// Downloads a file to disk, and supports background downloads.
    /// - Returns:.success(true), if successful
    func downloadFileWithStatusCode(url: URL, to localUrl: URL, config: RequestConfig? = nil, completion: @escaping (Result<(result: Bool, statusCode: Int?), NetworkError>) -> Void) -> NetworkCancellable? {
        log("\nNetworkService downloadFileWithStatusCode, url: \(url), to: \(localUrl)")
        
        let configAutoValidation: Bool = config?.autoValidation ?? defaultConfig.autoValidation!
        
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
