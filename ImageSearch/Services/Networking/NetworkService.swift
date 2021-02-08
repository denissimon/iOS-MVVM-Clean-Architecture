//
//  NetworkService.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

class NetworkService {
       
    var urlSession: URLSession
    var task: URLSessionTask?
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    // Request API endpoint
    func requestEndpoint(_ endpoint: EndpointType, params: HTTPParams? = nil, completion: @escaping (Result<Data>) -> Void) {
        
        let method = endpoint.method
        
        guard let url = endpoint.constructedURL else {
            completion(Result.error((nil, nil)))
            return
        }
        
        let request = RequestFactory.request(url: url, method: method, params: params)
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                completion(Result.done(data!))
                return
            }
            if error != nil {
                completion(Result.error((error!, status)))
            } else {
                completion(Result.error((nil, status)))
            }
        }
        
        dataTask.resume()
        task = dataTask
    }
    
    // Request API endpoint with automatic decoding of results in Codable
    func requestEndpoint<T: Codable>(_ endpoint: EndpointType, params: HTTPParams? = nil, type: T.Type, completion: @escaping (Result<T>) -> Void) {
        
        let method = endpoint.method
        
        guard let url = endpoint.constructedURL else {
            completion(Result.error((nil, nil)))
            return
        }
        
        let request = RequestFactory.request(url: url, method: method, params: params)
        
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                let response = ResponseDecodable(data: data!)
                guard let decoded = response.decode(type) else {
                    completion(Result.error((nil, status)))
                    return
                }
                completion(Result.done(decoded))
                return
            }
            
            if error != nil {
                completion(Result.error((error!, status)))
            } else {
                completion(Result.error((nil, status)))
            }
        }

        dataTask.resume()
        task = dataTask
    }
    
    // Perform any GET network task
    func get(url: URL, params: HTTPParams? = nil, completion: @escaping (Result<Data>) -> Void) {

        let request = RequestFactory.request(url: url, method: Method.GET, params: params)
        
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            let response = response as? HTTPURLResponse
            let status = response?.statusCode
            
            if data != nil && error == nil {
                completion(Result.done(data!))
                return
            }
            if error != nil {
                completion(Result.error((error!, status)))
            } else {
                completion(Result.error((nil, status)))
            }
        }
        
        dataTask.resume()
        task = dataTask
    }
    
    func cancelTask() {
        if let task = task {
            task.cancel()
        }
        task = nil
    }
}
