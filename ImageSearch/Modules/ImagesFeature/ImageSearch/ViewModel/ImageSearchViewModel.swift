//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

class ImageSearchViewModel {
    
    var networkService: NetworkService
    
    var lastSearchQuery: ImageQuery?
    
    // Bindings
    let data: Observable<[ImageSearchResults]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let resetSearchBar: Observable<Bool?> = Observable(nil)
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    let collectionViewTopConstraint: Observable<Float> = Observable(0)
    
    var downloadingTask: NetworkCancellable?
    
    init(networkService: NetworkService) {
        self.networkService = networkService
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
        
        if activityIndicatorVisibility.value {
            if searchQuery == lastSearchQuery {
                return
            }
            downloadingTask?.cancel()
        }
        activityIndicatorVisibility.value = true
        
        let imageQuery = ImageQuery(query: searchString)
        let endpoint = FlickrAPI.search(imageQuery: imageQuery)
        
        downloadingTask = networkService.requestEndpoint(endpoint) { [weak self] (result) in
            guard let self = self else { return }
                
            switch result {
            case .success(let data):
                do {
                    guard
                        !data.isEmpty,
                        let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
                        let stat = resultsDictionary["stat"] as? String
                        else {
                        self.showErrorToast()
                            return
                    }

                    if stat != "ok" {
                        self.showErrorToast()
                        return
                    }
                    
                    guard
                        let container = resultsDictionary["photos"] as? [String: AnyObject],
                        let photos = container["photo"] as? [[String: AnyObject]]
                        else {
                        self.showErrorToast()
                            return
                    }
                    
                    let imagesFound: [Image] = photos.compactMap { photoObject in
                        guard
                            let imageID = photoObject["id"] as? String,
                            let farm = photoObject["farm"] as? Int,
                            let server = photoObject["server"] as? String,
                            let secret = photoObject["secret"] as? String
                            else {
                                return nil
                        }

                        let image = Image(imageID: imageID, farm: farm, server: server, secret: secret, title: searchQuery.query)

                        guard
                            let url = image.getImageURL(),
                            let imageData = try? Data(contentsOf: url as URL)
                            else {
                                return nil
                        }

                        if let thumbnailImage = Supportive.getImage(data: imageData) {
                            image.thumbnail = ImageWrapper(image: thumbnailImage)
                            return image
                        } else {
                            return nil
                        }
                    }

                    let resultsWrapper = ImageSearchResults(searchQuery: searchQuery, searchResults: imagesFound)
                    self.data.value.insert(resultsWrapper, at: 0)
                    self.lastSearchQuery = searchQuery
                    
                    self.activityIndicatorVisibility.value = false
                } catch {
                    self.showErrorToast(error.localizedDescription)
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
