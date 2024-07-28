import Foundation

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
        
        let result = await self.imageRepository.searchImages(imageQuery)
        
        if imagesLoadTask != nil { guard !imagesLoadTask!.isCancelled else { return .success(nil) } }
        
        switch result {
        case .success(let imagesData):
            let images = await self.imageRepository.prepareImages(imagesData)
            
            guard images != nil else {
                return .failure(CustomError.app(.decoding))
            }
            
            if imagesLoadTask != nil { guard !imagesLoadTask!.isCancelled else { return .success(nil) } }
            
            let thumbnailImages = await withTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
                for item in images! {
                    taskGroup.addTask {
                        guard let thumbnailUrl = ImageBehavior.getFlickrImageURL(item, size: .thumbnail) else { return item }
                        var tempImage = item
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
            
            return .success(ImageSearchResults(id: self.generateSearchId(), searchQuery: imageQuery, searchResults: thumbnailImages))
        case .failure(let error):
            return .failure(error)
        }
    }
}
