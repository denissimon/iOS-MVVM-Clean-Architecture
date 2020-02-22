//
//  APIService.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

class APIService {
   
    // MARK: Properties
    
    var urlSession: URLSession

    // MARK: Initialization
    
    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    // MARK: Methods
    
    func constructUrl(for searchString: String) -> URL? {
        if let escapedString = searchString.encodeURIComponent() {
            return URL(string: "\(AppConstants.API.baseUrl)?method=flickr.photos.search&api_key=\(AppConstants.API.apiKey)&text=\(escapedString)&per_page=\(AppConstants.API.photosPerRequest)&format=json&nojsoncallback=1")
        } else {
            return nil
        }
    }
    
    func get(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let request = URLRequest(url: url)
        let dataTask = self.urlSession.dataTask(with: request) { (data, response, error) in
            completion(data, error)
        }
        dataTask.resume()
    }
}
