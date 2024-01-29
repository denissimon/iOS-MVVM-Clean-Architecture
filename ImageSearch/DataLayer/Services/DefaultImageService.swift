//
//  DefaultImageService.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/28/2024.
//

import Foundation

class DefaultImageService: ImageService {
    
    let imageRepository: ImageRepository
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }
    
    func searchImages(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>? = nil) async throws -> [Image]? {
        guard imagesLoadTask != nil, let imagesLoadTask = imagesLoadTask else { return nil }
                
        let result = await self.imageRepository.searchImages(imageQuery)
        
        guard !imagesLoadTask.isCancelled else { return nil }
        
        switch result {
        case .success(let imagesData):
            let images = await self.imageRepository.prepareImages(imagesData)
            
            guard images != nil else {
                throw NetworkError(error: nil, code: nil)
            }
            
            guard !imagesLoadTask.isCancelled else { return nil }
            
            let thumbnailImages = await withTaskGroup(of: Image.self, returning: [Image].self) { taskGroup in
                for item in images! {
                    taskGroup.addTask {
                        guard let thumbnailUrl = item.getImageURL(.thumbnail) else { return item }
                        let tempImage = item
                        if let thumbnailImageData = await self.imageRepository.getImage(url: thumbnailUrl) {
                            if let thumbnailImage = Supportive.toUIImage(from: thumbnailImageData) {
                                tempImage.thumbnail = ImageWrapper(image: thumbnailImage)
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
            
        case .failure(let error) :
            throw NetworkError.init(error: error.error, code: nil)
        }
    }
}
