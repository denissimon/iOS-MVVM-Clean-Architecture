//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation
import SwiftEvents

class ImageSearchViewModel {
    
    var networkService: NetworkService
    
    private(set) var data = [ImageSearchResults]() {
        didSet {
            DispatchQueue.main.async {
                self.updateData.trigger(nil)
            }
        }
    }
    
    var lastTag = String()
    
    // Event-based delegation
    let updateData = Event<Bool?>()
    let resetSearchBar = Event<Bool?>()
    let showToast = Event<String>()
    
    // Event-based observable properties
    let activityIndicatorVisibility = Observable<Bool>(false)
    let collectionViewTopConstraint = Observable<Float>(0)
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func searchFlickr(for searchString: String) {
        
        activityIndicatorVisibility.value = true
        
        func showErrorToast(_ msg: String = "") {
            DispatchQueue.main.async {
                if msg.isEmpty {
                    self.showToast.trigger("Network error")
                } else {
                    self.showToast.trigger(msg)
                }
                self.activityIndicatorVisibility.value = false
            }
        }
        
        guard let escapedString = searchString.encodeURIComponent() else {
            showErrorToast()
            return
        }
        
        let endpoint = FlickrAPI.search(string: escapedString)
        
        networkService.requestEndpoint(endpoint) { [weak self] (result) in
            guard let self = self else { return }
                
            switch result {
            case .done(let data):
                do {
                    guard
                        let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
                        let stat = resultsDictionary["stat"] as? String
                        else {
                            showErrorToast()
                            return
                    }

                    if stat != "ok" {
                        showErrorToast()
                        return
                    }
                    
                    guard
                        let container = resultsDictionary["photos"] as? [String: AnyObject],
                        let photos = container["photo"] as? [[String: AnyObject]]
                        else {
                            showErrorToast()
                            return
                    }

                    let photosFound: [Image] = photos.compactMap { photoObject in
                        guard
                            let imageID = photoObject["id"] as? String,
                            let farm = photoObject["farm"] as? Int,
                            let server = photoObject["server"] as? String,
                            let secret = photoObject["secret"] as? String
                            else {
                                return nil
                        }

                        let image = Image(imageID: imageID, farm: farm, server: server, secret: secret)

                        guard
                            let url = image.getImageURL(),
                            let imageData = try? Data(contentsOf: url as URL)
                            else {
                                return nil
                        }

                        if let thumbnailImage = Helpers.getImage(data: imageData) {
                            image.thumbnail = thumbnailImage
                            return image
                        } else {
                            return nil
                        }
                    }

                    let resultsWrapper = ImageSearchResults(searchString: searchString, searchResults: photosFound)
                    self.data.insert(resultsWrapper, at: 0)
                    self.lastTag = searchString
                    
                    DispatchQueue.main.async {
                        self.activityIndicatorVisibility.value = false
                        
                        let imageCount = resultsWrapper.searchResults.count
                        if imageCount > 1 {
                            self.showToast.trigger("Found \(imageCount) images")
                        } else {
                            self.showToast.trigger("Found 1 image")
                        }
                    }
                } catch {
                    showErrorToast(error.localizedDescription)
                }
            case .error(let error) :
                if error != nil {
                    showErrorToast(error!.localizedDescription)
                } else {
                    showErrorToast()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(with searchBarText: String?) {
        guard let searchBarText = searchBarText else { return }
        if !searchBarText.isEmpty {
            searchFlickr(for: searchBarText)
            resetSearchBar.trigger(nil)
        }
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
        return ImagesDataSource(with: data)
    }
    
    func getData() -> [ImageSearchResults] {
        return data
    }
    
    func getImage(for indexPath: (section: Int, row: Int)) -> Image {
        return data[indexPath.section].searchResults[indexPath.row]
    }
    
    func getSearchString(for section: Int) -> String {
        return data[section].searchString
    }
    
    func getHeightOfCell(width: Float) -> Float {
        let baseWidth = AppConstants.ImageCollection.BaseImageWidth
        if width > baseWidth {
            return baseWidth
        } else {
            return width
        }
    }
}
