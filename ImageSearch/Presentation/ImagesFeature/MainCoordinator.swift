import UIKit

@MainActor
protocol MainCoordinatorDIContainer {
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery, didFinish: Event<Image>) -> ImageDetailsViewController
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<String>) -> UIViewController
}

class MainCoordinator: FlowCoordinator {
    
    let navigationController: UINavigationController
    let dependencyContainer: MainCoordinatorDIContainer
        
    init(navigationController: UINavigationController, dependencyContainer: MainCoordinatorDIContainer) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
    }
    
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
    
    private func showImageDetails(image: ImageListItemVM, imageQuery: ImageQuery, didFinish: Event<Image>) {
        let imageDetailsVC = dependencyContainer.makeImageDetailsViewController(image: image as! Image, imageQuery: imageQuery, didFinish: didFinish)
        navigationController.pushViewController(imageDetailsVC, animated: true)
    }
    
    private func showHotTags(didSelect: Event<String>) {
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

