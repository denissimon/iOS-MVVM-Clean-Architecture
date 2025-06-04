import UIKit

@MainActor
protocol Alertable {}

extension Alertable where Self: UIViewController {
    
    func showAlert(title: String, message: String, style: UIAlertController.Style = .alert, okHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            if okHandler != nil { okHandler!() }
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    func makeToast(message: String, duration: TimeInterval = AppConfiguration.Other.toastDuration, position: ToastPosition = .bottom) {
        self.view.makeToast(message, duration: duration, position: position)
    }
    
    func makeToastActivity(position: ToastPosition = .center) {
        self.view.makeToastActivity(position)
    }
    
    func hideToastActivity() {
        self.view.hideToastActivity()
    }
}
