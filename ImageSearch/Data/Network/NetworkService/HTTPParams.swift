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

enum HTTPHeader: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case acceptLanguage = "Accept-Language"
    case connection = "Connection"
}

enum ContentType: String {
    case applicationJson = "application/json"
    case applicationJsonCharsetUTF8 = "application/json; charset=utf-8"
    case applicationFormUrlencoded = "application/x-www-form-urlencoded"
    case applicationFormUrlencodedCharsetUTF8 = "application/x-www-form-urlencoded; charset=utf-8"
    case multipartFormData = "multipart/form-data"
    case multipartFormDataCharsetUTF8 = "multipart/form-data; charset=utf-8"
    case textPlain = "text/plain"
    case textPlainCharsetUTF8 = "text/plain; charset=utf-8"
    case applicationXML = "application/xml"
    case applicationXMLCharsetUTF8 = "application/xml; charset=utf-8"
}
