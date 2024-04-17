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

public enum HTTPHeader: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case accept = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case acceptLanguage = "Accept-Language"
    case connection = "Connection"
}

public enum ContentType: String {
    case applicationJson = "application/json"
    case applicationFormUrlencoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
    case applicationXML = "application/xml"
    case applicationQuery = "application/query"
}
