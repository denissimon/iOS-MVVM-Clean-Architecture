//
//  NetworkService.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

struct NetworkError: Error {
    let error: Error?
    let code: Int?
}

class NetworkService {
       
    let urlSession: URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService request \(endpoint.method.rawValue), url: \(url)")
        
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
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        
        let request = RequestFactory.request(url: url, method: endpoint.method, params: endpoint.params)
        log("\nNetworkService request<T: Decodable> \(endpoint.method.rawValue), url: \(url)")
        
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
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        let request = RequestFactory.request(url: url, method: .GET, params: nil)
        log("\nNetworkService fetchFile: \(url)")
     
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
    
    func log(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
}

protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}

enum HTTPHeader: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case string = "String"
}

enum ContentType: String {
    case applicationJson = "application/json"
    case applicationFormUrlencoded = "application/x-www-form-urlencoded"
}

