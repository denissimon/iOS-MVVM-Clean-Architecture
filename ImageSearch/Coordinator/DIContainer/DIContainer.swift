import UIKit

class DIContainer {
  
    // MARK: - Network
    
    lazy var apiInteractor: APIInteractor = {
        let urlSession = URLSession.shared
        let networkService = NetworkService(urlSession: urlSession)
        return URLSessionAPIInteractor(with: networkService)
    }()
    
    // MARK: - Persistence
    
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
    
    // MARK: - Use Cases
    
    lazy var searchImagesUseCase: SearchImagesUseCase = {
        return DefaultSearchImagesUseCase(imageRepository: makeImageRepository())
    }()
    
    lazy var getBigImageUseCase: GetBigImageUseCase = {
        return DefaultGetBigImageUseCase(imageRepository: makeImageRepository())
    }()
    
    lazy var getHotTagsUseCase: GetHotTagsUseCase = {
        return DefaultGetHotTagsUseCase(tagRepository: makeTagRepository())
    }()
    
    // MARK: - Services
    
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
        let viewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        return ImageSearchViewController.instantiate(viewModel: viewModel, actions: actions)
    }
    
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery) -> ImageDetailsViewController {
        let viewModel = DefaultImageDetailsViewModel(getBigImageUseCase: getBigImageUseCase, image: image, imageQuery: imageQuery)
        return ImageDetailsViewController.instantiate(viewModel: viewModel)
    }
    
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsViewController {
        let viewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        return HotTagsViewController.instantiate(viewModel: viewModel, actions: actions)
    }
}
