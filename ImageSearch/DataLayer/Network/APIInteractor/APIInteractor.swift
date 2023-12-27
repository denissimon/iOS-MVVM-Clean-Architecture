//
//  APIInteractor.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol APIInteractor {
    @discardableResult
    func requestEndpoint(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable?
    
    @discardableResult
    func requestEndpoint<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable?
    
    @discardableResult
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable?
}

