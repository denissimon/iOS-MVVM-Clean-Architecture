//
//  URLSessionAPIInteractor.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

class URLSessionAPIInteractor: APIInteractor {
    
    let urlSessionAdapter: NetworkService
    
    init(with networkService: NetworkService) {
        self.urlSessionAdapter = networkService
    }
    
    func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.requestEndpoint(endpoint, completion: completion)
    }
    
    func requestEndpoint<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.requestEndpoint(endpoint, type: type, completion: completion)
    }
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        return urlSessionAdapter.fetchFile(url: url, completion: completion)
    }
}
