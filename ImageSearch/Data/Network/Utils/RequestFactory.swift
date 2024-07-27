import Foundation

class RequestFactory {
    static func request(url: URL, method: HTTPMethod, params: HTTPParams? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let params = params {
            if let httpBody = params.httpBody {
                switch httpBody {
                case is Data:
                    request.httpBody = httpBody as? Data
                case is Encodable:
                    if let encodable = httpBody as? Encodable {
                        request.httpBody = encodable.encode()
                    }
                default:
                    break
                }
            }
            if params.cachePolicy != nil { request.cachePolicy = params.cachePolicy! }
            if params.timeoutInterval != nil { request.timeoutInterval = params.timeoutInterval! }
            if params.headerValues != nil {
                for header in params.headerValues! {
                    request.addValue(header.value, forHTTPHeaderField: header.forHTTPHeaderField)
                }
            }
        }
        
        return request
    }
}
