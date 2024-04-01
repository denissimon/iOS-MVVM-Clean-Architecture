//
//  Endpoint.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

protocol EndpointType {
    var method: HTTPMethod { get }
    var baseURL: String { get }
    var path: String { get set }
    var params: HTTPParams? { get set }
}

class Endpoint: EndpointType {
    let method: HTTPMethod
    let baseURL: String
    var path: String
    var params: HTTPParams?
    
    init(method: HTTPMethod, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.params = params
    }
}
