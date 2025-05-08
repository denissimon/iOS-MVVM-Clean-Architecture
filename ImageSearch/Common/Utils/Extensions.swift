import UIKit
import SwiftUI

extension String {
    
    func encodeURIComponent() -> String? {
        self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }
    
    func decodeURIComponent() -> String? {
        self.removingPercentEncoding
    }
}

extension Array where Element == ImageWrapper {
    func toUIImageArray() -> [UIImage] {
        self.map { $0.uiImage ?? UIImage() }
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}

extension UIWindow {
    static var isLandscape: Bool {
        UIApplication.shared
            .keyWindow?
            .windowScene?
            .interfaceOrientation
            .isLandscape ?? false
    }
}

extension UIHostingController: Alertable { }
