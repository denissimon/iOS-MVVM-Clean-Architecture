//
//  HTTPParams.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/19/2020.
//

import Foundation

/// httpBody can be accepted as Data or Encodable
public struct HTTPParams {
    let httpBody: Any?
    let cachePolicy: URLRequest.CachePolicy?
    let timeoutInterval: TimeInterval?
    let headerValues: [(value: String, forHTTPHeaderField: String)]?
    
    public init(httpBody: Any?, cachePolicy: URLRequest.CachePolicy?, timeoutInterval: TimeInterval?, headerValues: [(value: String, forHTTPHeaderField: String)]?) {
        self.httpBody = httpBody
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.headerValues = headerValues
    }
}
