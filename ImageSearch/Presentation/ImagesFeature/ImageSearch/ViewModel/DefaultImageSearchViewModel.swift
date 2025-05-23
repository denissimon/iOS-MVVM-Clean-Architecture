import Foundation

/* Use case scenarios:
 * searchImagesUseCase.execute(imageQuery)
 * imageCachingService.cacheIfNecessary(data)
 * imageCachingService.getCachedImages(searchId: searchId)
 */

protocol ImageSearchViewModelInput {
    func searchImages(for query: ImageQuery)
    func searchBarSearchButtonClicked(with query: ImageQuery)
    func scrollUp()
    func scrollDown(_ searchBarHeight: Float)
    func updateSection(_ searchId: String)
    func getHeightOfCell(width: Float) -> Float
    func getDataSource() -> ImagesDataSource
}

protocol ImageSearchViewModelOutput {
    var data: Observable<[ImageSearchResultsListItemVM]> { get }
    var sectionData: Observable<([ImageSearchResultsListItemVM], IndexSet)> { get }
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
    
    var lastQuery: ImageQuery?
    
    let screenTitle = NSLocalizedString("Image Search", comment: "")
    
    // Bindings
    let data: Observable<[ImageSearchResultsListItemVM]> = Observable([])
    let sectionData: Observable<([ImageSearchResultsListItemVM], IndexSet)> = Observable(([],[]))
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
                self?.data.value = data
            }
        }
    }
    
    func getDataSource() -> ImagesDataSource {
        ImagesDataSource(with: data.value)
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
    
    func searchImages(for query: ImageQuery) {
        let searchString = query.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchString.isEmpty {
            makeToast.value = NSLocalizedString("Empty search query", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && query == lastQuery { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task {
            
            defer {
                memorySafetyCheck(data: data.value as! [ImageSearchResults])
            }
            
            let imageQuery = ImageQuery(query: searchString)
            let result = await searchImagesUseCase.execute(imageQuery)
            
            if Task.isCancelled { return }
            
            switch result {
            case .success(let searchResults):
                guard let searchResults = searchResults else {
                    activityIndicatorVisibility.value = false
                    return
                }
                
                data.value.insert(searchResults, at: 0)
                lastQuery = query
                
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
    
    func searchBarSearchButtonClicked(with query: ImageQuery) {
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
                        
            var sectionIndex = Int()
            
            for (index, search) in data.value.enumerated() {
                if search.id == searchId {
                    if let image = search._searchResults.first, image.thumbnail != nil { return }
                    search._searchResults = images
                    sectionIndex = index
                    break
                }
            }
            
            sectionData.value = (data.value, [sectionIndex])
        }
    }
}

extension DefaultImageSearchViewModel {
    var toTestImagesLoadTask: Task<Void, Never>? {
        imagesLoadTask
    }
}
