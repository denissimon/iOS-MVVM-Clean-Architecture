import Foundation

enum AppError: Error, LocalizedError {
    case `default`(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil, info: String? = nil)
    case server(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil, info: String? = nil)
    case unexpected(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil, info: String? = nil)
    
    var errorDescription: String? {
        switch self {
        case .default:
            return NSLocalizedString("The operation couldn’t be completed.", comment: "")
        case .server:
            return NSLocalizedString("A server error has occurred.", comment: "")
        case .unexpected:
            return NSLocalizedString("", comment: "")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .default:
            return NSLocalizedString("", comment: "")
        case .server:
            return NSLocalizedString("Please try again later.", comment: "")
        case .unexpected:
            return NSLocalizedString("Please check your Internet connection.", comment: "")
        }
    }
}
