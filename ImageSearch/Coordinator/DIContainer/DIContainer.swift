import UIKit

class DIContainer {
  
    // MARK: - Network
    
    lazy var apiInteractor: APIInteractor = {
        let urlSession = URLSession.shared
        let networkService = NetworkService(urlSession: urlSession)
        return URLSessionAPIInteractor(with: networkService)
    }()
    
    // MARK: - Storages
    
    lazy var imageDBInteractor: ImageDBInteractor = {
        let sqliteAdapter = try? SQLite(path: AppConfiguration.SQLite.imageSearchDBPath)
        return SQLiteImageDBInteractor(with: sqliteAdapter)
    }()
    
    // MARK: - Repositories
    
    func makeImageRepository() -> ImageRepository {
        return DefaultImageRepository(apiInteractor: apiInteractor, imageDBInteractor: imageDBInteractor)
    }
    
    func makeTagRepository() -> TagRepository {
        return DefaultTagRepository(apiInteractor: apiInteractor)
    }
    
    // MARK: - Services
    
    lazy var imageService: ImageService = {
        return DefaultImageService(imageRepository: makeImageRepository())
    }()
    
    lazy var imageCachingService: ImageCachingService = {
        return DefaultImageCachingService(imageRepository: makeImageRepository())
    }()
    
    // MARK: - Flow Coordinators
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        return MainCoordinator(navigationController: navigationController, dependencyContainer: self)
    }
}

// Optionally can be placed in a separate file DIContainer+MainCoordinatorDIContainer.swift
extension DIContainer: MainCoordinatorDIContainer {
    
    // MARK: - View Controllers
    
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController {
        let viewModel = DefaultImageSearchViewModel(imageService: imageService, imageCachingService: imageCachingService)
        return ImageSearchViewController.instantiate(viewModel: viewModel, actions: actions)
    }
    
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery) -> ImageDetailsViewController {
        let viewModel = DefaultImageDetailsViewModel(imageService: imageService, image: image, imageQuery: imageQuery)
        return ImageDetailsViewController.instantiate(viewModel: viewModel)
    }
    
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsViewController {
        let tagRepository = makeTagRepository()
        let viewModel = DefaultHotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        return HotTagsViewController.instantiate(viewModel: viewModel, actions: actions)
    }
}
