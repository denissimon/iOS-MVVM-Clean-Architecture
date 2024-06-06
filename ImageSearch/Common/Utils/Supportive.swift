import UIKit

class Supportive {
    
    static func toUIImage(from data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}

class DeepCopier {
    static func copy<T: Codable>(of object: T) -> T? {
       do {
           let json = try JSONEncoder().encode(object)
           return try JSONDecoder().decode(T.self, from: json)
       } catch {
           return nil
       }
    }
}

enum AppError: Error, LocalizedError {
    case `default`(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil, description: String? = nil)
    case server(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil)
    case unexpected(_ error: Error? = nil, statusCode: Int? = nil, data: Data? = nil)
    
    var failureReason: String? {
        switch self {
        case .server:
            return NSLocalizedString("A server error has occurred.", comment: "")
        case .unexpected:
            return ""
        default:
            return NSLocalizedString("The operation couldn’t be completed.", comment: "")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .server:
            return NSLocalizedString("Please try again later.", comment: "")
        case .unexpected:
            return NSLocalizedString("Please check your Internet connection.", comment: "")
        default:
            return ""
        }
    }
}
