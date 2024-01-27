//
//  NetworkService.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

public struct NetworkError: Error {
    let error: Error?
    let code: Int?
}

open class NetworkService {
       
    let urlSession: URLSession
    
    public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    /// Request API endpoint
    public func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestEndpoint: \(request.description)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                completion(.success(data!))
                return
            }
            if error != nil {
                completion(.failure(NetworkError(error: error!, code: status)))
            } else {
                completion(.failure(NetworkError(error: nil, code: status)))
            }
        }
        
        dataTask.resume()
        
        return dataTask
    }
    
    /// Request API endpoint with decoding of results in Decodable
    public func requestEndpoint<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService requestEndpoint<T: Decodable>: \(request.description)")
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                guard let decoded = ResponseDecodable.decode(type, data: data!) else {
                    completion(.failure(NetworkError(error: nil, code: status)))
                    return
                }
                completion(.success(decoded))
                return
            }
            
            if error != nil {
                completion(.failure(NetworkError(error: error!, code: status)))
            } else {
                completion(.failure(NetworkError(error: nil, code: status)))
            }
        }

        dataTask.resume()
        
        return dataTask
    }
    
    public func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(request.description)")
     
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            if data != nil && error == nil {
                completion(data!)
                return
            }
            return completion(nil)
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

public protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}

public enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case string = "String"
}

public enum ContentType: String {
    case applicationJson = "application/json"
    case applicationFormUrlencoded = "application/x-www-form-urlencoded"
}

