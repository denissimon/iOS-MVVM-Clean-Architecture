import Foundation

// callAsFunction() can be used instead of execute() to call instances of the use case class as if they were functions

protocol SearchImagesUseCase {
    func execute(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>?) async -> Result<ImageSearchResults?, CustomError>
}

class DefaultSearchImagesUseCase: SearchImagesUseCase {
    
    private let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    private func generateSearchId() -> String {
        UUID().uuidString
    }
    
    func execute(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>? = nil) async -> Result<ImageSearchResults?, CustomError> {
        
        let result = await imageRepository.searchImages(imageQuery)
        
        if imagesLoadTask != nil { guard !imagesLoadTask!.isCancelled else { return .success(nil) } }
        
        switch result {
        case .success(let imagesType):
            let thumbnailImages = await withTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
                for image in imagesType as! [Image] {
                    taskGroup.addTask {
                        guard let thumbnailUrl = ImageBehavior.getFlickrImageURL(image, size: .thumbnail) else { return image }
                        var tempImage = image
                        if let thumbnailImageData = await self.imageRepository.getImage(url: thumbnailUrl) {
                            if let thumbnailImage = Supportive.toUIImage(from: thumbnailImageData) {
                                let imageWrapper = ImageWrapper(uiImage: thumbnailImage)
                                tempImage = ImageBehavior.updateImage(tempImage, newWrapper: imageWrapper, for: .thumbnail)
                            }
                        }
                        return tempImage
                    }
                }
                var processedImages: [Image] = []
                for await result in taskGroup {
                    if result.thumbnail != nil {
                        processedImages.append(result)
                    }
                }
                return processedImages
            }
            
            return .success(ImageSearchResults(id: generateSearchId(), searchQuery: imageQuery, searchResults: thumbnailImages))
        case .failure(let error):
            return .failure(error)
        }
    }
}
