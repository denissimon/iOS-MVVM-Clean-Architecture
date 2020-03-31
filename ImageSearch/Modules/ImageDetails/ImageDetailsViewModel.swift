//
//  ImageDetailsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation
import SwiftEvents

class ImageDetailsViewModel {
    
    var networkService: NetworkService
    var tappedImage: Image
    var headerTitle: String
    
    // Closure-based delegates
    var updatesInData: ((UIImage) -> ())? = nil
    var shareImage: (([UIImage]) -> ())? = nil
    
    // Observable properties
    let showToast = Observable<String>("")
    
    init(networkService: NetworkService, tappedImage: Image, headerTitle: String) {
        self.networkService = networkService
        self.tappedImage = tappedImage
        self.headerTitle = headerTitle
        
        DispatchQueue.main.async {
            self.loadLargeImage()
        }
    }
    
    deinit {
        networkService.cancelTask()
    }
    
    func loadLargeImage() {
        loadLargeImage() { result in
            DispatchQueue.main.async {
                switch result {
                case .error(let error) :
                    if error != nil {
                        self.showToast.value = "Display error: \(error.debugDescription)"
                    } else {
                        self.showToast.value = "Display error"
                    }
                case .done(let results):
                    if let largeImage = results.largeImage {
                        self.updatesInData?(largeImage)
                    }
                }
            }
        }
    }
    
    private func loadLargeImage(_ completion: @escaping (Result<Image>) -> ()) {
        if let url = tappedImage.getImageURL("b") {
            networkService.get(url: url) { [weak self] (data, error) in
                guard let self = self else { return }
                    
                if let error = error {
                    completion(Result.error(error))
                    return
                }

                guard let data = data else {
                    completion(Result.error(nil))
                    return
                }

                let returnedImage = UIImage(data: data)
                    self.tappedImage.largeImage = returnedImage
                    completion(Result.done(self.tappedImage))
            }
        } else {
            completion(Result.error(nil))
        }
    }
    
    func getTitle() -> String {
        return headerTitle
    }
    
    func onShareButton() {
        if let largeImage = tappedImage.largeImage {
            shareImage?([largeImage])
        } else {
            self.showToast.value = "No image to share"
        }
    }
}
