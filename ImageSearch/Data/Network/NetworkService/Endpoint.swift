//
//  Endpoint.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

public protocol EndpointType {
    var method: Method { get }
    var path: String { get }
    var baseURL: String { get }
    var params: HTTPParams? { get set }
}

public class Endpoint: EndpointType {
    
    public var method: Method
    public var baseURL: String
    public var path: String
    public var params: HTTPParams?
    
    public init(method: Method, baseURL: String, path: String, params: HTTPParams?) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.params = params
    }
}
