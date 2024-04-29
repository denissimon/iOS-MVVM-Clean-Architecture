import UIKit

protocol MainCoordinatorDIContainer {
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery) -> ImageDetailsViewController
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsViewController
}

class MainCoordinator: FlowCoordinator {
    
    // MARK: - Properties
    let navigationController: UINavigationController
    let dependencyContainer: MainCoordinatorDIContainer
        
    // MARK: - Initializer
    init(navigationController: UINavigationController, dependencyContainer: MainCoordinatorDIContainer) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
    }
    
    // MARK: - Methods
    func start(completionHandler: CoordinatorStartCompletionHandler?) {
        showImageSearch()
    }
    
    private func showImageSearch() {
        let actions = ImageSearchCoordinatorActions(
            showImageDetails: showImageDetails,
            showHotTags: showHotTags
        )
        let imageSearchVC = dependencyContainer.makeImageSearchViewController(actions: actions)
        navigationController.pushViewController(imageSearchVC, animated: false)
    }
    
    private func showImageDetails(image: ImageListItemVM, imageQuery: ImageQuery) {
        let imageDetailsVC = dependencyContainer.makeImageDetailsViewController(image: image as! Image, imageQuery: imageQuery)
        navigationController.pushViewController(imageDetailsVC, animated: true)
    }
    
    private func showHotTags(didSelect: Event<ImageQuery>) {
        let actions = HotTagsCoordinatorActions(
            closeHotTags: closeHotTags
        )
        let hotTagsVC = dependencyContainer.makeHotTagsViewController(actions: actions, didSelect: didSelect)
        let hotTagsNC = UINavigationController(rootViewController: hotTagsVC)
        navigationController.topViewController?.show(hotTagsNC, sender: nil)
    }
    
    private func closeHotTags(viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

