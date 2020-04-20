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
    
    // Event-based delegation
    let updateData = Event<UIImage>()
    let shareImage = Event<[UIImage]>()
    let showToast = Event<String>()
    
    // Event-based observable properties
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    init(networkService: NetworkService, tappedImage: Image, headerTitle: String) {
        self.networkService = networkService
        self.tappedImage = tappedImage
        self.headerTitle = headerTitle
    }
    
    deinit {
        networkService.cancelTask()
    }
    
    func loadLargeImage() {
        
        func showErrorToast(_ msg: String = "") {
            DispatchQueue.main.async {
                if msg.isEmpty {
                    self.showToast.trigger("Network error")
                } else {
                    self.showToast.trigger(msg)
                }
            }
        }
        
        if let largeImage = tappedImage.largeImage {
            updateData.trigger(largeImage)
            return
        }
        
        if let url = tappedImage.getImageURL("b") {
            
            self.activityIndicatorVisibility.value = true
            
            networkService.get(url: url) { [weak self] (result) in
                guard let self = self else { return }
                    
                switch result {
                case .done(let data):
                    let returnedImage = UIImage(data: data)
                    self.tappedImage.largeImage = returnedImage
                    if let largeImage = returnedImage {
                        DispatchQueue.main.async {
                            self.updateData.trigger(largeImage)
                            self.activityIndicatorVisibility.value = false
                        }
                    }
                case .error(let error):
                    if error != nil {
                        showErrorToast(error!.localizedDescription)
                    } else {
                        showErrorToast()
                    }
                }
            }
        } else {
            showErrorToast()
        }
    }
    
    func getTitle() -> String {
        return headerTitle
    }
    
    func onShareButton() {
        if let largeImage = tappedImage.largeImage {
            shareImage.trigger([largeImage])
        } else {
            self.showToast.trigger("No image to share")
        }
    }
}
