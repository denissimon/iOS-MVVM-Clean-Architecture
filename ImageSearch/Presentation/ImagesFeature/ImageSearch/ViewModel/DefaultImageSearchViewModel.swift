import Foundation

/* Use case scenarios:
 * searchImagesUseCase.execute(imageQuery)
 * imageCachingService.cacheIfNecessary(data)
 * imageCachingService.getCachedImages(searchId: searchId)
 */

@MainActor
protocol ImageSearchViewModelInput {
    func searchImages(for query: String)
    func searchBarSearchButtonClicked(with query: String)
    func scrollUp()
    func scrollDown(_ searchBarHeight: Float)
    func updateSection(_ searchId: String)
    func updateImage(_ image: Image, indexPath: IndexPath)
    func getHeightOfCell(width: Float) -> Float
}

@MainActor
protocol ImageSearchViewModelOutput {
    var data: Observable<(searches: [ImageSearchResultsVM], reload: Bool)> { get }
    var reloadSection: Observable<IndexSet> { get }
    var scrollTop: Observable<Bool?> { get }
    var makeToast: Observable<String> { get }
    var resetSearchBar: Observable<Bool?> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var collectionViewTopConstraint: Observable<Float> { get }
    var lastQuery: ImageQuery? { get }
    var screenTitle: String { get }
}

typealias ImageSearchViewModel = ImageSearchViewModelInput & ImageSearchViewModelOutput

class DefaultImageSearchViewModel: ImageSearchViewModel {
    
    private let searchImagesUseCase: SearchImagesUseCase
    private let imageCachingService: ImageCachingService
    
    private var imageSearchResults: [ImageSearchResults] = []
    
    private(set) var lastQuery: ImageQuery?
    
    let screenTitle = NSLocalizedString("Image Search", comment: "")
    
    // Bindings
    let data: Observable<(searches: [ImageSearchResultsVM], reload: Bool)> = Observable(([], true))
    let reloadSection: Observable<IndexSet> = Observable([])
    let scrollTop: Observable<Bool?> = Observable(nil)
    let makeToast: Observable<String> = Observable("")
    let resetSearchBar: Observable<Bool?> = Observable(nil)
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    let collectionViewTopConstraint: Observable<Float> = Observable(0)
    
    private var imagesLoadTask: Task<Void, Never>? {
        willSet { imagesLoadTask?.cancel() }
    }
    
    init(searchImagesUseCase: SearchImagesUseCase, imageCachingService: ImageCachingService) {
        self.searchImagesUseCase = searchImagesUseCase
        self.imageCachingService = imageCachingService
        
        setup()
    }
    
    private func setup() {
        Task {
            await imageCachingService.subscribeToDidProcess(self) { [weak self] data in
                Task { @MainActor in
                    guard let self else { return }
                    self.imageSearchResults = data
                    self.data.value = (data, true)
                }
            }
        }
    }
    
    private func showError(_ msg: String = "") {
        makeToast.value = !msg.isEmpty ? msg : NSLocalizedString("An error has occurred", comment: "")
        activityIndicatorVisibility.value = false
    }
    
    private func memorySafetyCheck(data: [ImageSearchResults]) {
        if AppConfiguration.MemorySafety.enabled {
            Task {
                await imageCachingService.cacheIfNecessary(data)
            }
        }
    }
    
    func searchImages(for query: String) {
        guard let imageQuery = ImageQuery(query: query) else {
            makeToast.value = NSLocalizedString("Search query error", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && query == lastQuery?.query { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task {
            
            defer {
                memorySafetyCheck(data: imageSearchResults)
            }
            
            let result = await searchImagesUseCase.execute(imageQuery)
            
            if Task.isCancelled { return }
            
            switch result {
            case .success(let searchResults):
                guard let searchResults = searchResults else {
                    activityIndicatorVisibility.value = false
                    return
                }
                
                imageSearchResults.insert(searchResults, at: 0)
                data.value = (imageSearchResults, true)
                lastQuery = imageQuery
                
                activityIndicatorVisibility.value = false
                scrollTop.value = nil
            case .failure(let error):
                let defaultMessage = ((error.errorDescription ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                switch error {
                case CustomError.app(_, let customMessage):
                    showError(customMessage ?? defaultMessage)
                default:
                    showError(defaultMessage)
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(with query: String) {
        searchImages(for: query)
        resetSearchBar.value = nil
    }
    
    func scrollUp() {
        if collectionViewTopConstraint.value != 0 {
            collectionViewTopConstraint.value = 0
        }
    }
    
    func scrollDown(_ searchBarHeight: Float) {
        if collectionViewTopConstraint.value == 0 {
            collectionViewTopConstraint.value = searchBarHeight * -1
        }
    }
    
    func getHeightOfCell(width: Float) -> Float {
        let baseWidth = AppConfiguration.ImageCollection.baseImageWidth
        if width > baseWidth {
            return baseWidth
        } else {
            return width
        }
    }
    
    func updateSection(_ searchId: String) {
        Task {
            guard let images = await imageCachingService.getCachedImages(searchId: searchId) else { return }
            guard !images.isEmpty else { return }
            
            for (index, search) in imageSearchResults.enumerated() {
                if search.id == searchId {
                    if let image = search.searchResults.first, image.thumbnail != nil { return }
                    imageSearchResults[index].searchResults = images
                    data.value = (imageSearchResults, false)
                    reloadSection.value = [index]
                    break
                }
            }
        }
    }
    
    func updateImage(_ image: Image, indexPath: IndexPath) {
        guard imageSearchResults.indices.contains(indexPath.section) else { return }
        guard imageSearchResults[indexPath.section]._searchResults.indices.contains(indexPath.row) else { return }
        imageSearchResults[indexPath.section]._searchResults[indexPath.row] = image
        data.value = (imageSearchResults, false)
    }
}

extension DefaultImageSearchViewModel {
    
    var toTestImagesLoadTask: Task<Void, Never>? {
        imagesLoadTask
    }
    
    var toTestImageSearchResults: [ImageSearchResults] {
        get { imageSearchResults }
        set { imageSearchResults = newValue }
    }
}
