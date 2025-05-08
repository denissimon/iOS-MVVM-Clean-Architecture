import Foundation

/* Use case scenarios:
 * searchImagesUseCase.execute(imageQuery)
 * imageCachingService.cacheIfNecessary(data)
 * imageCachingService.getCachedImages(searchId: searchId)
 */

protocol ImageSearchViewModelInput {
    func searchImage(for searchQuery: ImageQuery)
    func searchBarSearchButtonClicked(with searchBarQuery: ImageQuery)
    func scrollUp()
    func scrollDown(_ searchBarHeight: Float)
    func updateSection(_ searchId: String)
    func getHeightOfCell(width: Float) -> Float
}

protocol ImageSearchViewModelOutput {
    var data: Observable<(data: [ImageSearchResultsListItemVM], reload: Bool)> { get }
    var sectionData: Observable<IndexSet> { get }
    var scrollTop: Observable<Bool?> { get }
    var makeToast: Observable<String> { get }
    var resetSearchBar: Observable<Bool?> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var collectionViewTopConstraint: Observable<Float> { get }
    var lastSearchQuery: ImageQuery? { get }
    var screenTitle: String { get }
}

typealias ImageSearchViewModel = ImageSearchViewModelInput & ImageSearchViewModelOutput

class DefaultImageSearchViewModel: ImageSearchViewModel {
    
    private let searchImagesUseCase: SearchImagesUseCase
    private let imageCachingService: ImageCachingService
    
    var lastSearchQuery: ImageQuery?
    
    let screenTitle = NSLocalizedString("Image Search", comment: "")
    
    private var imageSearchResults: [ImageSearchResults] = []
    
    // Bindings
    let data: Observable<(data: [ImageSearchResultsListItemVM], reload: Bool)> = Observable(([],true))
    let sectionData: Observable<IndexSet> = Observable([])
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
            await imageCachingService.subscribeToDidProcess(self) { result in
                self.imageSearchResults = result
                self.data.value = (result, true)
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
    
    func searchImage(for searchQuery: ImageQuery) {
        let searchString = searchQuery.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchString.isEmpty {
            makeToast.value = NSLocalizedString("Empty search query", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && searchQuery == lastSearchQuery { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task {
            
            defer {
                self.memorySafetyCheck(data: self.imageSearchResults)
            }
            
            let imageQuery = ImageQuery(query: searchString)
            let result = await self.searchImagesUseCase.execute(imageQuery)
            
            if self.imagesLoadTask != nil { guard !self.imagesLoadTask!.isCancelled else { return } }
            
            switch result {
            case .success(let searchResults):
                guard !Task.isCancelled else { return }
                
                guard let searchResults = searchResults else {
                    self.activityIndicatorVisibility.value = false
                    return
                }
                
                self.imageSearchResults.insert(searchResults, at: 0)
                self.data.value.data.insert(searchResults, at: 0)
                self.lastSearchQuery = searchQuery
                
                self.activityIndicatorVisibility.value = false
                self.scrollTop.value = nil
            case .failure(let error):
                let defaultMessage = ((error.errorDescription ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                switch error {
                case CustomError.app(_, let customMessage):
                    self.showError(customMessage ?? defaultMessage)
                default:
                    self.showError(defaultMessage)
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(with searchBarQuery: ImageQuery) {
        searchImage(for: searchBarQuery)
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
            guard let images = await imageCachingService.getCachedImages(searchId: searchId),
                    !images.isEmpty else { return }
            
            var sectionIndex = Int()
            
            for (index, search) in imageSearchResults.enumerated() {
                if search.id == searchId {
                    if let image = search.searchResults.first, image.thumbnail != nil { return }
                    imageSearchResults[index].searchResults = images
                    data.value = (imageSearchResults, false)
                    sectionIndex = index
                    break
                }
            }
            
            sectionData.value = [sectionIndex]
        }
    }
}

extension DefaultImageSearchViewModel {
    var toTestImageSearchResults: [ImageSearchResults] {
        get {
            Supportive.isRunningUnitTests() ? imageSearchResults : []
        }
        set {
            if Supportive.isRunningUnitTests() { imageSearchResults = newValue }
        }
    }
}
