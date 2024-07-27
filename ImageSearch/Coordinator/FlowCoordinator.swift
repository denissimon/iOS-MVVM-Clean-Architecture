import UIKit

typealias CoordinatorStartCompletionHandler = () -> ()

protocol FlowCoordinator {
    var navigationController: UINavigationController { get }
    func start(completionHandler: CoordinatorStartCompletionHandler?)
}

