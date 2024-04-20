import Foundation

actor DefaultImageCachingService: ImageCachingService {
    
    private let imageRepository: ImageRepository
    
    // To avoid reading from cache and updating UI while writing to cache may be in progress
    var checkingInProgress = false
    
    // To prevent images with the same searchId from being read again from the cache
    var searchIdsToGetFromCache: Set<String> = []
    
    let didProcess: Event<[ImageSearchResults]> = Event()
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
        Task.detached {
            await self.deleteAllImages()
        }
    }
    
    // Clear the Image table at the app's start
    private func deleteAllImages() async {
        await self.imageRepository.deleteAllImages()
    }
    
    func cacheIfNecessary(_ data: [ImageSearchResults]) async {
        checkingInProgress = true
        
        if data.count <= AppConfiguration.MemorySafety.cacheAfterSearches {
            checkingInProgress = false
            return
        }
        searchIdsToGetFromCache = []
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
                    for (index, image) in search.searchResults.enumerated(){
                        search.searchResults[index] = ImageBehavior.updateImage(image, newWrapper: nil, for: .big) // We don't necessarily need to cache big images in the local DB since they are already cached for a while by iOS
                        if !imagesAreCached { // cache if image is not already cached
                            let _ = await self.imageRepository.saveImage(image, searchId: search.id, sortId: index+1)
                        }
                        search.searchResults[index] = ImageBehavior.updateImage(image, newWrapper: nil, for: .thumbnail)
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
        if !searchIdsToGetFromCache.contains(searchId) {
            searchIdsToGetFromCache.insert(searchId)
            return await self.imageRepository.getImages(searchId: searchId)
        } else {
            return nil
        }
    }
}
