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
    
    private(set) var image: Image
    private let imageQuery: ImageQuery
    private let didFinish: Event<Image>
    
    // Bindings
    let data: Observable<ImageWrapper?> = Observable(nil)
    let shareImage: Observable<[ImageWrapper]> = Observable([])
    let makeToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    
    private var imageLoadTask: Task<Void, Never>? {
        willSet { imageLoadTask?.cancel() }
    }
    
    init(getBigImageUseCase: GetBigImageUseCase, image: Image, imageQuery: ImageQuery, didFinish: Event<Image>) {
        self.getBigImageUseCase = getBigImageUseCase
        self.image = image
        self.imageQuery = imageQuery
        self.didFinish = didFinish
    }
    
    deinit {
        imageLoadTask?.cancel()
        didFinish.notify(image)
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
        
        imageLoadTask = Task { [weak self] in
            guard let image = self?.image else { return }
            
            if let imageData = await self?.getBigImageUseCase.execute(for: image) {
                
                if Task.isCancelled { return }
                
                guard let self else { return }
                guard !imageData.isEmpty else {
                    showError()
                    return
                }
                
                if let bigImage = Supportive.toUIImage(from: imageData) {
                    let imageWrapper = ImageWrapper(uiImage: bigImage)
                    self.image = ImageBehavior.updateImage(image, newWrapper: imageWrapper, for: .big)
                    data.value = imageWrapper
                    
                    activityIndicatorVisibility.value = false
                } else {
                    showError()
                }
            } else {
                if !Task.isCancelled {
                    self?.showError()
                }
            }
        }
    }
    
    func getTitle() -> String {
        imageQuery.query
    }
    
    func onShareButton() {
        if let bigImage = image.bigImage {
            shareImage.value = [bigImage]
        } else {
            makeToast.value = NSLocalizedString("No image to share", comment: "")
        }
    }
}

extension DefaultImageDetailsViewModel {
    var toTestImageLoadTask: Task<Void, Never>? {
        imageLoadTask
    }
}
