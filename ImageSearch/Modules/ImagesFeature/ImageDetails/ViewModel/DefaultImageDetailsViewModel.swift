import Foundation

/* Use Case scenarios:
 * imageService.getBigImage(for: self.image)
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
    
    private let imageService: ImageService
    
    var image: Image
    let imageQuery: ImageQuery
    
    // Bindings
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable<Bool>(false)
    
    private var imageLoadTask: Task<Void, Never>?
    
    init(imageService: ImageService, image: Image, imageQuery: ImageQuery) {
        self.imageService = imageService
        self.image = image
        self.imageQuery = imageQuery
    }
    
    deinit {
        imageLoadTask?.cancel()
    }
    
    private func showErrorToast(_ msg: String = "") {
        showToast.value = !msg.isEmpty ? msg : NSLocalizedString("An error has occurred", comment: "")
        activityIndicatorVisibility.value = false
    }
    
    func loadBigImage() {
        if let bigImage = image.bigImage {
            data.value = bigImage
            return
        }
        
        activityIndicatorVisibility.value = true
        
        imageLoadTask = Task.detached { [weak self] in
            guard let image = self?.image else { return }
            if let imageData = await self?.imageService.getBigImage(for: image) {
                guard !imageData.isEmpty else {
                    self?.showErrorToast()
                    return
                }
                if let bigImage = Supportive.toUIImage(from: imageData) {
                    let imageWrapper = ImageWrapper(image: bigImage)
                    self?.image = ImageBehavior.updateImage(image, newWrapper: imageWrapper, for: .big)
                    self?.data.value = imageWrapper
                    
                    self?.activityIndicatorVisibility.value = false
                } else {
                    self?.showErrorToast()
                }
            } else {
                self?.showErrorToast()
            }
        }
    }
    
    func getTitle() -> String {
        return imageQuery.query
    }
    
    func onShareButton() {
        if let bigImage = image.bigImage {
            shareImage.value = [bigImage]
        } else {
            self.showToast.value = NSLocalizedString("No image to share", comment: "")
        }
    }
}
