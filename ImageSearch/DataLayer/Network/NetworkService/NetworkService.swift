//
//  NetworkService.swift
//  CryptocurrencyInfo
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

protocol EndpointType {
    var method: Method { get }
    var path: String { get }
    var baseURL: String { get }
    var params: HTTPParams? { get set }
}

class Endpoint: EndpointType {
    var method: Method
    var baseURL: String
    var path: String
    var params: HTTPParams?
    init(method: Method, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.params = params
    }
}

struct HTTPParams {
    let httpBody: Data?
    let cachePolicy: URLRequest.CachePolicy?
    let timeoutInterval: TimeInterval?
    let headerValues: [(value: String, forHTTPHeaderField: String)]?
}

struct NetworkError: Error {
    let error: Error?
    let code: Int?
}

class NetworkService {
       
    var urlSession: URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    // Request API endpoint
    func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        print("\nNetworkService requestEndpoint:",request)
        
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
    
    // Request API endpoint with decoding of results in Decodable
    func requestEndpoint<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        print("\nNetworkService requestEndpoint<T: Decodable>:",request)
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                let response = ResponseDecodable(data: data!)
                guard let decoded = response.decode(type) else {
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
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        print("\nNetworkService fetchFile:",request)
     
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            if data != nil && error == nil {
                completion(data!)
                return
            }
            return completion(nil)
        }
        
        dataTask.resume()
        
        return dataTask
    }
}

struct ResponseDecodable {
    
    fileprivate var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    public func decode<T: Decodable>(_ type: T.Type) -> T? {
        let jsonDecoder = JSONDecoder()
        do {
            let response = try jsonDecoder.decode(T.self, from: data)
            return response
        } catch _ {
            return nil
        }
    }
}

enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case string = "String"
}

enum ContentType: String {
    case json = "application/json"
    case formEncode = "application/x-www-form-urlencoded"
}

