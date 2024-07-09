import Foundation

actor DefaultImageCachingService: ImageCachingService {
    
    private let imageRepository: ImageRepository
    
    // To avoid reading from cache and updating UI while writing to cache may be in progress
    private(set) var cachingTask: Task<Void, Never>? = nil
    
    // To prevent images with the same searchId from being read again from the cache
    private(set) var searchIdsFromCache: Set<String> = []
    
    let didProcess: Event<[ImageSearchResults]> = Event()
    
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
        Task {
            await deleteAllImages()
        }
    }
    
    // Clear the Image table at the app's start
    private func deleteAllImages() async {
        await imageRepository.deleteAllImages()
    }
    
    // Called after each new search
    func cacheIfNecessary(_ data: [ImageSearchResults]) async {
        if data.count <= AppConfiguration.MemorySafety.cacheAfterSearches { return }
        if cachingTask != nil { return }
        
        cachingTask = Task {
            searchIdsFromCache = []
            let dataPart1 = Array(data.prefix(AppConfiguration.MemorySafety.cacheAfterSearches))
            let dataPart2 = Array(data.suffix(data.count - AppConfiguration.MemorySafety.cacheAfterSearches))
            let processedPart2 = await processData(dataPart2)
            let newData = dataPart1 + processedPart2
            didProcess.notify(newData)
            try? await Task.sleep(nanoseconds: 500_000_000)
            cachingTask = nil
        }
        
        await cachingTask!.value
    }
    
    private func processData(_ data: [ImageSearchResults]) async -> [ImageSearchResults] {
        await withTaskGroup(of: ImageSearchResults.self, returning: [ImageSearchResults].self) { taskGroup in
            
            for search in data {
                taskGroup.addTask {
                    if search.searchResults.first?.thumbnail == nil {
                        return search
                    }
                    guard let imagesAreCached = await self.imageRepository.checkImagesAreCached(searchId: search.id) else {
                        return search
                    }
                    for (index, image) in search.searchResults.enumerated(){
                        let image = image as! Image
                        // We don't necessarily need to cache big images in the local DB since they are already cached for a while by iOS
                        search.searchResults[index] = ImageBehavior.updateImage(image, newWrapper: nil, for: .big)
                        if !imagesAreCached {
                            // Cache the thumbnail if it's not already cached
                            let _ = await self.imageRepository.saveImage(image, searchId: search.id, sortId: index+1)
                        }
                        search.searchResults[index] = ImageBehavior.updateImage(image, newWrapper: nil, for: .thumbnail)
                    }
                    return search
                }
            }
            
            var processedData = data
            
            for await editedSearch in taskGroup {
                // The tasks are executed concurrently, so we need to make sure that the edited searches are reassembled in the correct order in which they were originally done
                for (index, search) in data.enumerated() {
                    if search.id == editedSearch.id {
                        processedData[index] = editedSearch
                        break
                    }
                }
            }
            return processedData
        }
    }
    
    func getCachedImages(searchId: String) async -> [Image]? {
        if !searchIdsFromCache.contains(searchId) {
            searchIdsFromCache.insert(searchId)
            if let images = await self.imageRepository.getImages(searchId: searchId) as? [Image] {
                return images
            }
        }
        return nil
    }
}
