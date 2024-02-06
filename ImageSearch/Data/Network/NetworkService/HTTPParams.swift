//
//  HTTPParams.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

/// httpBody can be accepted as Data or Encodable
struct HTTPParams {
    var httpBody: Any?
    var cachePolicy: URLRequest.CachePolicy?
    var timeoutInterval: TimeInterval?
    var headerValues: [(value: String, forHTTPHeaderField: String)]?
    
    init(httpBody: Any?, cachePolicy: URLRequest.CachePolicy?, timeoutInterval: TimeInterval?, headerValues: [(value: String, forHTTPHeaderField: String)]?) {
        self.httpBody = httpBody
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.headerValues = headerValues
    }
}
