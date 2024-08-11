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
        DefaultImageRepository(apiInteractor: apiInteractor, imageDBInteractor: imageDBInteractor)
    }
    
    func makeTagRepository() -> TagRepository {
        DefaultTagRepository(apiInteractor: apiInteractor)
    }
    
    // MARK: - Use Cases
    
    func makeSearchImagesUseCase() -> SearchImagesUseCase {
        DefaultSearchImagesUseCase(imageRepository: makeImageRepository())
    }
    
    func makeGetBigImageUseCase() -> GetBigImageUseCase {
        DefaultGetBigImageUseCase(imageRepository: makeImageRepository())
    }
    
    func makeGetHotTagsUseCase() -> GetHotTagsUseCase {
        DefaultGetHotTagsUseCase(tagRepository: makeTagRepository())
    }
    
    // MARK: - Services
    
    lazy var imageCachingService: ImageCachingService = {
        DefaultImageCachingService(imageRepository: makeImageRepository())
    }()
    
    // MARK: - Flow Coordinators
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(navigationController: navigationController, dependencyContainer: self)
    }
}

// Optionally can be placed in a separate file DIContainer+MainCoordinatorDIContainer.swift
extension DIContainer: MainCoordinatorDIContainer {
    
    // MARK: - View Controllers
    
    func makeImageSearchViewController(actions: ImageSearchCoordinatorActions) -> ImageSearchViewController {
        let viewModel = DefaultImageSearchViewModel(searchImagesUseCase: makeSearchImagesUseCase(), imageCachingService: imageCachingService)
        return ImageSearchViewController.instantiate(viewModel: viewModel, actions: actions)
    }
    
    func makeImageDetailsViewController(image: Image, imageQuery: ImageQuery) -> ImageDetailsViewController {
        let viewModel = DefaultImageDetailsViewModel(getBigImageUseCase: makeGetBigImageUseCase(), image: image, imageQuery: imageQuery)
        return ImageDetailsViewController.instantiate(viewModel: viewModel)
    }
    
    func makeHotTagsViewController(actions: HotTagsCoordinatorActions, didSelect: Event<ImageQuery>) -> HotTagsViewController {
        let viewModel = DefaultHotTagsViewModel(getHotTagsUseCase: makeGetHotTagsUseCase(), didSelect: didSelect)
        return HotTagsViewController.instantiate(viewModel: viewModel, actions: actions)
    }
}
