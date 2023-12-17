//
//  MainCoordinator.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/15/2023.
//

import UIKit

protocol MainCoordinatorDIContainer {
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController
    func makeImageDetailsViewController(image: Image) -> ImageDetailsViewController
    func makeHotTagsListViewController(actions: HotTagsListCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsListViewController
}

class MainCoordinator: Coordinator {
    
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
            showHotTagsList: showHotTagsList
        )
        let imageSearchVC = dependencyContainer.makeImageSearchViewController(actions: actions)
        navigationController.pushViewController(imageSearchVC, animated: false)
    }
    
    private func showImageDetails(image: Image) {
        let imageDetailsVC = dependencyContainer.makeImageDetailsViewController(image: image)
        navigationController.pushViewController(imageDetailsVC, animated: true)
    }
    
    private func showHotTagsList(didSelect: Event<ImageQuery>) {
        let actions = HotTagsListCoordinatorActions(
            closeHotTagsList: closeHotTagsList
        )
        let hotTagsListVC = dependencyContainer.makeHotTagsListViewController(actions: actions, didSelect: didSelect)
        let hotTagsListNC = UINavigationController(rootViewController: hotTagsListVC)
        navigationController.topViewController?.show(hotTagsListNC, sender: nil)
    }
    
    private func closeHotTagsList(viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

