//
//  ImageDetailsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import Foundation

class ImageDetailsViewModel {
    
    let imageRepository: ImageRepository
    let image: Image
    let imageQuery: ImageQuery
    
    // Bindings
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    private var imageLoadTask: Cancellable?
    
    init(imageRepository: ImageRepository, image: Image, imageQuery: ImageQuery) {
        self.imageRepository = imageRepository
        self.image = image
        self.imageQuery = imageQuery
    }
    
    deinit {
        imageLoadTask?.cancel()
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
        if let largeImage = image.largeImage {
            data.value = largeImage
            return
        }
        
        if let url = image.getImageURL(.big) {
            
            activityIndicatorVisibility.value = true
                    
            imageLoadTask = imageRepository.getLargeImage(url: url) { [weak self] (result) in
                guard let self = self else { return }
                    
                switch result {
                case .success(let data):
                    if let largeImage = Supportive.getImage(data: data) {
                        let imageWrapper = ImageWrapper(image: largeImage)
                        self.image.largeImage = imageWrapper
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
        return imageQuery.query
    }
    
    func onShareButton() {
        if let largeImage = image.largeImage {
            shareImage.value = [largeImage]
        } else {
            self.showToast.value = "No image to share"
        }
    }
}
