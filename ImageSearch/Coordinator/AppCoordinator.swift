import UIKit

class AppCoordinator: FlowCoordinator {
    
    lazy var navigationController = UINavigationController()
    let dependencyContainer: DIContainer
        
    init(dependencyContainer: DIContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    func start(completionHandler: CoordinatorStartCompletionHandler?) {
        let mainCoordinator = dependencyContainer.makeMainCoordinator(navigationController: navigationController)
        mainCoordinator.start(completionHandler: nil)
    }
}

