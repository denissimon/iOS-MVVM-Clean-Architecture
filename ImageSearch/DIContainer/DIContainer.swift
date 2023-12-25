//
//  DIContainer.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/15/2023.
//

import UIKit

class DIContainer {
  
    // MARK: - Network
    
    lazy var apiInteractor: APIInteractor = {
        let urlSession = URLSession.shared
        let networkService = NetworkService(urlSession: urlSession)
        return URLSessionAPIInteractor(with: networkService)
    }()
    
    // MARK: - Repositories
    
    func makeImageRepository() -> ImageRepository {
       return DefaultImageRepository(apiInteractor: apiInteractor)
    }
    
    func makeTagRepository() -> TagRepository {
       return DefaultTagRepository(apiInteractor: apiInteractor)
    }
    
    // MARK: - Flow Coordinators
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        return MainCoordinator(navigationController: navigationController, dependencyContainer: self)
    }
}

// Optionally can be placed in a separate file DIContainer+MainCoordinatorDIContainer.swift
extension DIContainer: MainCoordinatorDIContainer {
    
    // MARK: - View Controllers
    
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController {
        let imageRepository = makeImageRepository()
        let viewModel = ImageSearchViewModel(imageRepository: imageRepository)
        return ImageSearchViewController.instantiate(viewModel: viewModel, actions: actions)
    }
    
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery) -> ImageDetailsViewController {
        let imageRepository = makeImageRepository()
        let viewModel = ImageDetailsViewModel(imageRepository: imageRepository, image: image, imageQuery: imageQuery)
        return ImageDetailsViewController.instantiate(viewModel: viewModel)
    }
    
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsViewController {
        let tagRepository = makeTagRepository()
        let viewModel = HotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        return HotTagsViewController.instantiate(viewModel: viewModel, actions: actions)
    }
}
