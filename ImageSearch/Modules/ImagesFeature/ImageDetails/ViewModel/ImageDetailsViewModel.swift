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
    
    // Bindings
    let updateData: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let showToast: Observable<String> = Observable("")
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
            self.showToast.value = "Network error"
        } else {
            self.showToast.value = msg
        }
        self.activityIndicatorVisibility.value = false
    }
    
    func loadLargeImage() {
        if let largeImage = tappedImage.largeImage {
            updateData.value = largeImage
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
                        self.updateData.value = imageWrapper
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
            shareImage.value = [largeImage]
        } else {
            self.showToast.value = "No image to share"
        }
    }
}
