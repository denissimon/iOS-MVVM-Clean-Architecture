import UIKit

typealias CoordinatorStartCompletionHandler = () -> ()

@MainActor
protocol FlowCoordinator {
    var navigationController: UINavigationController { get }
    func start(completionHandler: CoordinatorStartCompletionHandler?)
}

