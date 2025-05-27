import Foundation

class RequestFactory {
    static func request(_ endpoint: EndpointType) -> URLRequest? {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let params = endpoint.params {
            request.httpBody = params.httpBody
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
