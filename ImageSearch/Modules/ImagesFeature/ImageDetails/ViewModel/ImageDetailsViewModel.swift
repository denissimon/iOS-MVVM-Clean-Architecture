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
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    var downloadingTask: NetworkCancellable?
    
    init(networkService: NetworkService, tappedImage: Image) {
        self.networkService = networkService
        self.tappedImage = tappedImage
    }
    
    deinit {
        downloadingTask?.cancel()
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
            data.value = largeImage
            return
        }
        
        if let url = tappedImage.getImageURL(.big) {
            
            activityIndicatorVisibility.value = true
                    
            downloadingTask = networkService.fetchFile(url: url) { [weak self] (result) in
                guard let self = self else { return }
                    
                switch result {
                case .success(let data):
                    if let returnedImage = Supportive.getImage(data: data) {
                        let imageWrapper = ImageWrapper(image: returnedImage)
                        self.tappedImage.largeImage = imageWrapper
                        self.data.value = imageWrapper
                        self.activityIndicatorVisibility.value = false
                    } else {
                        self.showErrorToast()
                    }
                case .failure(let error):
                    if error.error != nil {
                        self.showErrorToast(error.error!.localizedDescription)
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
