//
//  RequestFactory.swift
//  ImageSearch
//
//  Created by Denis Simon on 03/09/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

enum Method: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

class RequestFactory {
    
    static func request(method: Method, url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }
}
