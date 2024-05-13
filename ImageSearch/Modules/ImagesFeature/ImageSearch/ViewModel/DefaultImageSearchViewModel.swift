import Foundation

/* Use Case scenarios:
 * imageService.searchImages(imageQuery)
 * imageCachingService.cacheIfNecessary(self.data.value)
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
    var data: Observable<[ImageSearchResults]> { get }
    var sectionData: Observable<([ImageSearchResults], IndexSet)> { get }
    var scrollTop: Observable<Bool?> { get }
    var showToast: Observable<String> { get }
    var resetSearchBar: Observable<Bool?> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var collectionViewTopConstraint: Observable<Float> { get }
    var lastSearchQuery: ImageQuery? { get }
    var screenTitle: String { get }
}

typealias ImageSearchViewModel = ImageSearchViewModelInput & ImageSearchViewModelOutput

class DefaultImageSearchViewModel: ImageSearchViewModel {
    
    private let imageService: ImageService
    private let imageCachingService: ImageCachingService
    
    var lastSearchQuery: ImageQuery?
    
    let screenTitle = NSLocalizedString("Image Search", comment: "")
    
    // Bindings
    let data: Observable<[ImageSearchResults]> = Observable([])
    let sectionData: Observable<([ImageSearchResults], IndexSet)> = Observable(([],[]))
    let scrollTop: Observable<Bool?> = Observable(nil)
    let showToast: Observable<String> = Observable("")
    let resetSearchBar: Observable<Bool?> = Observable(nil)
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    let collectionViewTopConstraint: Observable<Float> = Observable(0)
    
    private var imagesLoadTask: Task<Void, Never>? {
        willSet { imagesLoadTask?.cancel() }
    }
    
    init(imageService: ImageService, imageCachingService: ImageCachingService) {
        self.imageService = imageService
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
    
    private func showErrorToast(_ msg: String = "") {
        if msg.isEmpty {
            self.showToast.value = NSLocalizedString("Network error", comment: "")
        } else {
            self.showToast.value = msg
        }
        self.activityIndicatorVisibility.value = false
    }
    
    func searchImage(for searchQuery: ImageQuery) {
        let trimmedString = searchQuery.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedString.isEmpty {
            showToast.value = NSLocalizedString("Empty search query", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        guard let searchString = trimmedString.encodeURIComponent() else {
            showToast.value = NSLocalizedString("Search query error", comment: "")
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && searchQuery == lastSearchQuery { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task.detached {
            
            var thumbnailImages: [Image]?
            
            do {
                let imageQuery = ImageQuery(query: searchString)
                thumbnailImages = try await self.imageService.searchImages(imageQuery, imagesLoadTask: self.imagesLoadTask)
            } catch {
                self.showErrorToast(error.localizedDescription)
                return
            }
            
            guard !Task.isCancelled else { return }
            
            guard let thumbnailImages = thumbnailImages else {
                self.activityIndicatorVisibility.value = false
                return
            }
            
            let resultsWrapper = ImageSearchResults(id: self.generateSearchId(), searchQuery: searchQuery, searchResults: thumbnailImages)
            self.data.value.insert(resultsWrapper, at: 0)
            self.lastSearchQuery = searchQuery
            
            self.activityIndicatorVisibility.value = false
            self.scrollTop.value = nil
            
            self.memorySafetyCheck()
        }
    }
    
    private func generateSearchId() -> String {
        UUID().uuidString
    }
    
    private func memorySafetyCheck() {
        if AppConfiguration.MemorySafety.enabled {
            Task {
                await imageCachingService.cacheIfNecessary(self.data.value)
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
        Task.detached {
            guard await !self.imageCachingService.checkingInProgress else { return }
            guard await !self.imageCachingService.searchIdsToGetFromCache.contains(searchId) else { return }
            
            if let images = await self.imageCachingService.getCachedImages(searchId: searchId) {
                if images.isEmpty { return }
                
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
