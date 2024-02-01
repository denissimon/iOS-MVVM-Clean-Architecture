//
//  DefaultImageDetailsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import Foundation

/* Use Case scenarios:
 * imageRepository.getImage(url: bigImageURL)
 */

protocol ImageDetailsViewModelInput {
    func loadBigImage()
    func getTitle() -> String
    func onShareButton()
}

protocol ImageDetailsViewModelOutput {
    var data: Observable<ImageWrapper?> { get }
    var shareImage: Observable<[ImageWrapper]> { get }
    var showToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var image: Image { get }
}

typealias ImageDetailsViewModel = ImageDetailsViewModelInput & ImageDetailsViewModelOutput

class DefaultImageDetailsViewModel: ImageDetailsViewModel {
    
    let imageRepository: ImageRepository
    let image: Image
    let imageQuery: ImageQuery
    
    // Bindings
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable<Bool>(false)
    
    private var imageLoadTask: Task<Void, Never>?
    
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
    
    func loadBigImage() {
        if let bigImage = image.bigImage {
            data.value = bigImage
            return
        }
        
        if let bigImageURL = ImageBehavior.getImageURL(image, size: .big) {
            
            activityIndicatorVisibility.value = true
            
            imageLoadTask = Task.detached { [weak self] in
                guard let self = self else { return }
                if let data = await self.imageRepository.getImage(url: bigImageURL) {
                    guard !data.isEmpty else {
                        self.showErrorToast()
                        return
                    }
                    if let bigImage = Supportive.toUIImage(from: data) {
                        let imageWrapper = ImageWrapper(image: bigImage)
                        self.image.bigImage = imageWrapper
                        self.data.value = imageWrapper
                        self.activityIndicatorVisibility.value = false
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
        if let bigImage = image.bigImage {
            shareImage.value = [bigImage]
        } else {
            self.showToast.value = "No image to share"
        }
    }
}
