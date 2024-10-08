import Foundation

/* Use case scenarios:
 * getBigImageUseCase.execute(for: image)
 */

protocol ImageDetailsViewModelInput {
    func loadBigImage()
    func getTitle() -> String
    func onShareButton()
}

protocol ImageDetailsViewModelOutput {
    var data: Observable<ImageWrapper?> { get }
    var shareImage: Observable<[ImageWrapper]> { get }
    var makeToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var image: Image { get }
}

typealias ImageDetailsViewModel = ImageDetailsViewModelInput & ImageDetailsViewModelOutput

class DefaultImageDetailsViewModel: ImageDetailsViewModel {
    
    private let getBigImageUseCase: GetBigImageUseCase
    
    var image: Image
    let imageQuery: ImageQuery
    
    // Bindings
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let makeToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable<Bool>(false)
    
    private var imageLoadTask: Task<Void, Never>?
    
    init(getBigImageUseCase: GetBigImageUseCase, image: Image, imageQuery: ImageQuery) {
        self.getBigImageUseCase = getBigImageUseCase
        self.image = image
        self.imageQuery = imageQuery
    }
    
    deinit {
        imageLoadTask?.cancel()
    }
    
    private func showError(_ msg: String = "") {
        makeToast.value = !msg.isEmpty ? msg : NSLocalizedString("An error has occurred", comment: "")
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
            if let imageData = await self?.getBigImageUseCase.execute(for: image) {
                guard !imageData.isEmpty else {
                    self?.showError()
                    return
                }
                if let bigImage = Supportive.toUIImage(from: imageData) {
                    let imageWrapper = ImageWrapper(uiImage: bigImage)
                    self?.image = ImageBehavior.updateImage(image, newWrapper: imageWrapper, for: .big)
                    self?.data.value = imageWrapper
                    
                    self?.activityIndicatorVisibility.value = false
                } else {
                    self?.showError()
                }
            } else {
                self?.showError()
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
            makeToast.value = NSLocalizedString("No image to share", comment: "")
        }
    }
}
