//
//  DIContainer.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/15/2023.
//

import UIKit

class DIContainer {
  
    // MARK: - Flow Coordinators
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        return MainCoordinator(navigationController: navigationController, dependencyContainer: self)
    }
}

// Optionally can be placed in a separate file DIContainer+MainCoordinatorDIContainer.swift
extension DIContainer: MainCoordinatorDIContainer {
    
    // MARK: - View Controllers
    
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController {
        let viewModel = ImageSearchViewModel(networkService: NetworkService())
        return ImageSearchViewController.instantiate(viewModel: viewModel, actions: actions)
    }
    
    func makeImageDetailsViewController(image: Image) -> ImageDetailsViewController {
        let viewModel = ImageDetailsViewModel(networkService: NetworkService(), tappedImage: image)
        return ImageDetailsViewController.instantiate(viewModel: viewModel)
    }
    
    func makeHotTagsListViewController(actions: HotTagsListCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsListViewController {
        let viewModel = HotTagsListViewModel(networkService: NetworkService(), didSelect: didSelect)
        return HotTagsListViewController.instantiate(viewModel: viewModel, actions: actions)
    }
}
