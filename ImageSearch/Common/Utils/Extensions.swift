import UIKit

extension String {
    
    func encodeURIComponent() -> String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }
    
    func decodeURIComponent() -> String? {
        return self.removingPercentEncoding
    }
}

extension Array where Element == ImageWrapper {
    func toUIImageArray() -> [UIImage] {
        return self.map { $0.uiImage ?? UIImage() }
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        return self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}

extension UIWindow {
    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return UIApplication.shared
                .keyWindow?
                .windowScene?
                .interfaceOrientation
                .isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}
