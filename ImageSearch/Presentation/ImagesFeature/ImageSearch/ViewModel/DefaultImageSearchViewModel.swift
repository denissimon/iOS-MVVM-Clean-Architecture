import Foundation

/* Use cases:
 * searchImagesUseCase.execute(imageQuery)
 * imageCachingService.cacheIfNecessary(data)
 * imageCachingService.getCachedImages(searchId: searchId)
 */

protocol ImageSearchViewModelInput {
    func searchImage(for searchQuery: ImageQuery)
    func getDataSource() -> ImagesDataSource
    func searchBarSearchButtonClicked(with searchBarQuery: ImageQuery)
    func scrollUp()
    func scrollDown(_ searchBarHeight: Float)
    func updateSection(_ searchId: String)
    func getHeightOfCell(width: Float) -> Float
}

protocol ImageSearchViewModelOutput {
    var data: Observable<[ImageSearchResultsListItemVM]> { get }
    var sectionData: Observable<([ImageSearchResultsListItemVM], IndexSet)> { get }
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
            await imageCachingService.didProcess.subscribe(self) { result in
                self.data.value = result
            }
        }
    }
    
    func getDataSource() -> ImagesDataSource {
        return ImagesDataSource(with: data.value)
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
        let trimmedString = searchQuery.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedString.isEmpty {
            makeToast.value = NSLocalizedString("Empty search query", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        guard let searchString = trimmedString.encodeURIComponent() else {
            makeToast.value = NSLocalizedString("Search query error", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && searchQuery == lastSearchQuery { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task.detached {
            
            defer {
                self.memorySafetyCheck(data: self.data.value)
            }
            
            var searchResults: ImageSearchResults?
            
            do {
                let imageQuery = ImageQuery(query: searchString)
                searchResults = try await self.searchImagesUseCase.execute(imageQuery, imagesLoadTask: self.imagesLoadTask)
            } catch {
                if error is AppError {
                    let error = error as! AppError
                    let msg = ((error.errorDescription ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                    self.showError(msg)
                } else {
                    self.showError(error.localizedDescription)
                }
                return
            }
            
            guard !Task.isCancelled else { return }
            
            guard let searchResults = searchResults else {
                self.activityIndicatorVisibility.value = false
                return
            }
            
            self.data.value.insert(searchResults, at: 0)
            self.lastSearchQuery = searchQuery
            
            self.activityIndicatorVisibility.value = false
            self.scrollTop.value = nil
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
            guard await self.imageCachingService.cachingTask == nil else { return }
            
            if let images = await self.imageCachingService.getCachedImages(searchId: searchId) {
                guard !images.isEmpty else { return }
                
                let dataCopy = self.data.value
                var sectionIndex = Int()
                for (index, search) in dataCopy.enumerated() {
                    if search.id == searchId {
                        if let image = search.searchResults.first {
                            if image.thumbnail != nil { return }
                        }
                        search.searchResults = images
                        sectionIndex = index
                        break
                    }
                }
                
                self.sectionData.value = (dataCopy, [sectionIndex])
            }
        }
    }
}
