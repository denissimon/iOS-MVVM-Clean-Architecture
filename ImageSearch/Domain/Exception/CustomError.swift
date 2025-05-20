import Foundation

enum CustomError: LocalizedError {
    case app(_ type: AppError? = nil, description: String? = nil)
    case server(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil)
    case internetConnection(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil)
    case unexpected(_ error: Error? = nil)
    
    enum AppError {
        case apiClient
        case database
        case different
    }
    
    var errorDescription: String? {
        switch self {
        case .app:
            return NSLocalizedString("The operation couldn’t be completed.", comment: "")
        case .server:
            return NSLocalizedString("A server error has occurred.", comment: "")
        case .internetConnection:
            return NSLocalizedString("", comment: "")
        default:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .app:
            return NSLocalizedString("", comment: "")
        case .server:
            return NSLocalizedString("Please try again later.", comment: "")
        case .internetConnection:
            return NSLocalizedString("Please check your Internet connection.", comment: "")
        default:
            return nil
        }
    }
}
