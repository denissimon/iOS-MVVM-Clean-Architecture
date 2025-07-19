/// https://datatracker.ietf.org/doc/html/rfc7231#section-4.3
enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    case HEAD
    case OPTIONS
    case CONNECT
    case TRACE
    case QUERY /// https://www.ietf.org/archive/id/draft-ietf-httpbis-safe-method-w-body-02.html
}
