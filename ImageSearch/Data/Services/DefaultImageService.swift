import Foundation

class DefaultImageService: ImageService {
    
    private let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    func searchImages(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>? = nil) async throws -> [Image]? {
        let result = await self.imageRepository.searchImages(imageQuery)
        
        if imagesLoadTask != nil { guard !imagesLoadTask!.isCancelled else { return nil } }
        
        switch result {
        case .success(let imagesData):
            let images = await self.imageRepository.prepareImages(imagesData)
            
            guard images != nil else {
                throw AppError.default()
            }
            
            if imagesLoadTask != nil { guard !imagesLoadTask!.isCancelled else { return nil } }
            
            let thumbnailImages = await withTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
                for item in images! {
                    taskGroup.addTask {
                        guard let thumbnailUrl = ImageBehavior.getFlickrImageURL(item, size: .thumbnail) else { return item }
                        var tempImage = item
                        if let thumbnailImageData = await self.imageRepository.getImage(url: thumbnailUrl) {
                            if let thumbnailImage = Supportive.toUIImage(from: thumbnailImageData) {
                                let imageWrapper = ImageWrapper(image: thumbnailImage)
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
            
            return thumbnailImages
            
        case .failure(let error):
            throw error
        }
    }
    
    func getBigImage(for image: Image) async -> Data? {
        if let bigImageURL = ImageBehavior.getFlickrImageURL(image, size: .big) {
            if let imageData = await self.imageRepository.getImage(url: bigImageURL) {
                return imageData
            }
        }
        return nil
    }
}
