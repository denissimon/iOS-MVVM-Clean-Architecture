//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

/* Use Case scenarios:
 * imageRepository.searchImages(imageQuery)
 * imageRepository.prepareImages(imagesData)
 * imageRepository.getImage(url: thumbnailUrl)
 * imageCachingService.cacheIfNecessary(self.data.value)
 * imageCachingService.getCachedImages(searchId: searchId)
 */

class ImageSearchViewModel {
    
    let imageRepository: ImageRepository
    
    let imageCachingService: ImageCachingService
    
    var lastSearchQuery: ImageQuery?
    
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
    
    init(imageRepository: ImageRepository, imageCachingService: ImageCachingService) {
        self.imageRepository = imageRepository
        self.imageCachingService = imageCachingService
        
        setup()
    }
    
    private func setup() {
        imageCachingService.didProcess.subscribe(self) { result in
            self.data.value = result
        }
    }
    
    func showErrorToast(_ msg: String = "") {
        if msg.isEmpty {
            self.showToast.value = "Network error"
        } else {
            self.showToast.value = msg
        }
        self.activityIndicatorVisibility.value = false
    }
    
    func searchFlickr(for searchQuery: ImageQuery) {
        let trimmedString = searchQuery.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedString.isEmpty {
            showToast.value = "Empty search query"
            resetSearchBar.value = nil
            return
        }
        
        guard let searchString = trimmedString.encodeURIComponent() else {
            showToast.value = "Search query error"
            resetSearchBar.value = nil
            return
        }
        
        if activityIndicatorVisibility.value && searchQuery == lastSearchQuery { return }
        activityIndicatorVisibility.value = true
        
        imagesLoadTask = Task.detached {
            
            let imageQuery = ImageQuery(query: searchString)
            let result = await self.imageRepository.searchImages(imageQuery)
            
            guard !Task.isCancelled else { return }
            
            switch result {
            case .success(let imagesData):
                let images = await self.imageRepository.prepareImages(imagesData)
                
                guard images != nil else {
                    self.showErrorToast()
                    return
                }
                
                guard !Task.isCancelled else { return }
                
                let thumbnailImages = await withTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
                    for item in images! {
                        taskGroup.addTask {
                            guard let thumbnailUrl = item.getImageURL(.medium) else { return item }
                            let tempImage = item
                            if let thumbnailImageData = await self.imageRepository.getImage(url: thumbnailUrl) {
                                if let thumbnailImage = Supportive.toUIImage(from: thumbnailImageData) {
                                    tempImage.thumbnail = ImageWrapper(image: thumbnailImage)
                                }
                            }
                            return tempImage
                        }
                    }
                    var processedImages: [Image] = []
                    for await result in taskGroup {
                        if result.thumbnail != nil {
                            processedImages.append(result)
                        }
                    }
                    return processedImages
                }
                
                guard !Task.isCancelled else { return }
                
                let resultsWrapper = ImageSearchResults(id: self.generateSearchId(), searchQuery: searchQuery, searchResults: thumbnailImages)
                self.data.value.insert(resultsWrapper, at: 0)
                self.lastSearchQuery = searchQuery
                
                self.activityIndicatorVisibility.value = false
                self.scrollTop.value = nil
                
                self.memorySafetyCheck()
            case .failure(let error) :
                if error.error != nil {
                    self.showErrorToast(error.error!.localizedDescription)
                } else {
                    self.showErrorToast()
                }
            }
        }
    }
    
    private func generateSearchId() -> String {
        UUID().uuidString
    }
    
    private func memorySafetyCheck() {
        if AppConfiguration.MemorySafety.enabled {
            Task.detached {
                await self.imageCachingService.cacheIfNecessary(self.data.value)
            }
        }
    }
    
    func searchBarSearchButtonClicked(with searchBarQuery: ImageQuery) {
        searchFlickr(for: searchBarQuery)
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
    
    func getDataSource() -> ImagesDataSource {
        return ImagesDataSource(with: data.value)
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
        guard !imageCachingService.checkingInProgress else { return }
        guard !imageCachingService.idsToGetFromCache.contains(searchId) else { return }
        Task.detached {
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
