//
//  HTTPParams.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/12/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

struct HTTPParams {
    // For adding values to the request headers.
    let headerValues: [(value: String, forHTTPHeaderField: String)]?
    
    // The data sent as the message body of a request, such as for an HTTP POST request.
    let httpBody: Data?
    
    // The request’s cache policy.
    let cachePolicy: URLRequest.CachePolicy?
}
