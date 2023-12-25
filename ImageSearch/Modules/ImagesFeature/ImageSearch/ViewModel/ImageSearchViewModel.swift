//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

class ImageSearchViewModel {
    
    let imageRepository: ImageRepository
    
    var lastSearchQuery: ImageQuery?
    
    // Bindings
    let data: Observable<[ImageSearchResults]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let resetSearchBar: Observable<Bool?> = Observable(nil)
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    let collectionViewTopConstraint: Observable<Float> = Observable(0)
    
    private var imagesLoadTask: Cancellable? {
        willSet { imagesLoadTask?.cancel() }
    }
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
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
        
        if activityIndicatorVisibility.value && searchQuery == lastSearchQuery {
            return
        }
        activityIndicatorVisibility.value = true
        
        let imageQuery = ImageQuery(query: searchString)
        imagesLoadTask = imageRepository.searchImages(imageQuery){ [weak self] (result) in
            guard let self = self else { return }
                
            switch result {
            case .success(let data):
                self.imageRepository.prepareImages(data) { images in
                    guard images != nil else {
                        self.showErrorToast()
                        return
                    }
                    
                    let resultsWrapper = ImageSearchResults(searchQuery: searchQuery, searchResults: images!.data)
                    self.data.value.insert(resultsWrapper, at: 0)
                    self.lastSearchQuery = searchQuery
                    
                    self.activityIndicatorVisibility.value = false
                }
            case .failure(let error) :
                if error.error != nil {
                    self.showErrorToast(error.error!.localizedDescription)
                } else {
                    self.showErrorToast()
                }
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
}
