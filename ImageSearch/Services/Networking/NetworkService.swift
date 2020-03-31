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
    
    func get(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let request = URLRequest(url: url)
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            completion(data, error)
        }
        dataTask.resume()
        task = dataTask
    }
    
    func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Data?, Error?) -> Void) {
        
        let method = endpoint.method
        guard let url = endpoint.constructedURL else {
            completion(nil, nil)
            return
        }
        let request = RequestFactory.request(method: method, url: url)
        
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
