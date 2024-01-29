//
//  DefaultImageCachingService.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/02/2024.
//

import Foundation

class DefaultImageCachingService: ImageCachingService {
    
    let imageRepository: ImageRepository
    
    // To avoid reading from cache and updating UI while writing to cache may be in progress
    var checkingInProgress = false
    
    // Contains a set of searchIds, the images of which are retrieved from the cache
    var idsToGetFromCache: Set<String> = []
    
    var didProcess: Event<[ImageSearchResults]> = Event()
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
        deleteAllImages()
    }
    
    // Clear the Image table at the app's start
    private func deleteAllImages() {
        Task.detached {
            await self.imageRepository.deleteAllImages()
        }
    }
    
    func cacheIfNecessary(_ data: [ImageSearchResults]) async {
        checkingInProgress = true
        
        if data.count <= AppConfiguration.MemorySafety.cacheAfterSearches {
            checkingInProgress = false
            return
        }
        idsToGetFromCache = []
        let dataPart1 = Array(data.prefix(AppConfiguration.MemorySafety.cacheAfterSearches))
        let dataPart2 = Array(data.suffix(data.count - AppConfiguration.MemorySafety.cacheAfterSearches))
        let processedPart2 = await processData(dataPart2)
        let newData = dataPart1 + processedPart2
        didProcess.notify(newData)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        checkingInProgress = false
    }
    
    private func processData(_ data: [ImageSearchResults]) async -> [ImageSearchResults] {
        let processedData = await withTaskGroup(of: ImageSearchResults.self, returning: [ImageSearchResults].self) { taskGroup in
            for search in data {
                taskGroup.addTask {
                    if search.searchResults.first?.thumbnail == nil {
                        return search
                    }
                    guard let imagesAreCached = await self.imageRepository.checkImagesAreCached(searchId: search.id) else {
                        return search
                    }
                    for (index, image) in search.searchResults .enumerated(){
                        image.bigImage = nil // We don't necessarily need to cache big images in the local DB, since they are already cached by iOS for a while and are displayed even when offline
                        if !imagesAreCached { // cache if image is not already cached
                            let _ = await self.imageRepository.saveImage(image, searchId: search.id, sortId: index+1)
                        }
                        image.thumbnail = nil
                    }
                    return search
                }
            }
            var results: [ImageSearchResults] = []
            for await item in taskGroup {
                results.append(item)
            }
            return results
        }
        return processedData
    }
    
    func getCachedImages(searchId: String) async -> [Image]? {
        if !idsToGetFromCache.contains(searchId) {
            idsToGetFromCache.insert(searchId)
            let images = await self.imageRepository.getImages(searchId: searchId)
            return images
        } else {
            return nil
        }
    }
}
