import Foundation

class RequestFactory {
    static func request(_ endpoint: EndpointType) -> URLRequest? {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let params = endpoint.params {
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
