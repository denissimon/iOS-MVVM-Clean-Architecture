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
    
    func requestEndpoint(_ endpoint: EndpointType, params: HTTPParams? = nil, completion: @escaping (Data?, Error?) -> Void) {
        
        let method = endpoint.method
        guard let url = endpoint.constructedURL else {
            completion(nil, nil)
            return
        }
        let request = RequestFactory.request(method: method, params: params, url: url)
        
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            completion(data, error)
        }
        dataTask.resume()
        
        task = dataTask
    }
    
    func get(url: URL, params: HTTPParams? = nil, completion: @escaping (Data?, Error?) -> Void) {
        let request = RequestFactory.request(method: Method.GET, params: params, url: url)
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            completion(data, error)
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
