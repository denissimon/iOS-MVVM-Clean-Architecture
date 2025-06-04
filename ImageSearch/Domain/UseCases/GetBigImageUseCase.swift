import Foundation

// callAsFunction() can be used instead of execute() to call instances of the use case class as if they were functions

protocol GetBigImageUseCase: Sendable {
    func execute(for image: Image) async -> Data?
}

final class DefaultGetBigImageUseCase: GetBigImageUseCase {
    
    private let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    func execute(for image: Image) async -> Data? {
        if let bigImageURL = ImageBehavior.getFlickrImageURL(image, size: .big) {
            if let imageData = await imageRepository.getImage(url: bigImageURL) {
                return imageData
            }
        }
        return nil
    }
}

