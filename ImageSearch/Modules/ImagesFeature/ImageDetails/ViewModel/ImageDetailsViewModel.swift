//
//  ImageDetailsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import Foundation

class ImageDetailsViewModel {
    
    var networkService: NetworkService
    var tappedImage: Image
    
    // Delegates
    let updateData = Event<ImageWrapper>()
    let shareImage = Event<[ImageWrapper]>()
    let showToast = Event<String>()
    
    // Bindings
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    init(networkService: NetworkService, tappedImage: Image) {
        self.networkService = networkService
        self.tappedImage = tappedImage
    }
    
    deinit {
        networkService.cancelTask()
    }
    
    func showErrorToast(_ msg: String = "") {
        if msg.isEmpty {
            self.showToast.trigger("Network error")
        } else {
            self.showToast.trigger(msg)
        }
        self.activityIndicatorVisibility.value = false
    }
    
    func loadLargeImage() {
        if let largeImage = tappedImage.largeImage {
            updateData.trigger(largeImage)
            return
        }
        
        if let url = tappedImage.getImageURL("b") {
            
            activityIndicatorVisibility.value = true
            
            networkService.get(url: url) { [weak self] (result) in
                guard let self = self else { return }
                    
                switch result {
                case .done(let data):
                    if let returnedImage = Supportive.getImage(data: data) {
                        let imageWrapper = ImageWrapper(image: returnedImage)
                        self.tappedImage.largeImage = imageWrapper
                        self.updateData.trigger(imageWrapper)
                        self.activityIndicatorVisibility.value = false
                    } else {
                        self.showErrorToast()
                    }
                case .error(let error):
                    if error.0 != nil {
                        self.showErrorToast(error.0!.localizedDescription)
                    } else {
                        self.showErrorToast()
                    }
                }
            }
        } else {
            showErrorToast()
        }
    }
    
    func getTitle() -> String {
        return tappedImage.title
    }
    
    func onShareButton() {
        if let largeImage = tappedImage.largeImage {
            shareImage.trigger([largeImage])
        } else {
            self.showToast.trigger("No image to share")
        }
    }
}
