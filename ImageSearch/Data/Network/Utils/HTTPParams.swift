import Foundation

struct HTTPParams {
    var httpBody: Data?
    var cachePolicy: URLRequest.CachePolicy?
    var timeoutInterval: TimeInterval?
    var headerValues: [(value: String, forHTTPHeaderField: String)]?
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
    case applicationFormUrlencoded = "application/x-www-form-urlencoded"
    case multipartFormData = "multipart/form-data"
    case textPlain = "text/plain"
    case applicationXML = "application/xml"
    case applicationQuery = "application/query"
}
