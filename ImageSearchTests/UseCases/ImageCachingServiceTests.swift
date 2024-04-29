import XCTest
@testable import ImageSearch

class ImageCachingServiceTests: XCTestCase {
    
    static let searchResultsStub = [
        ImageSearchResults(id: "id5", searchQuery: ImageQuery(query: "query5"), searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil), Image(title: "image4", flickr: nil)]),
        ImageSearchResults(id: "id4", searchQuery: ImageQuery(query: "query4"), searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil), Image(title: "image4", flickr: nil)]),
        ImageSearchResults(id: "id3", searchQuery: ImageQuery(query: "query3"), searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil)]),
        ImageSearchResults(id: "id2", searchQuery: ImageQuery(query: "query2"), searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil)]),
        ImageSearchResults(id: "id1", searchQuery: ImageQuery(query: "query1"), searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil)])
    ]
    
    static let cachedImagesStub = [
        (image: Image(title: "image1", flickr: nil), searchId: "id2", sortId: 1), (image: Image(title: "image2", flickr: nil), searchId: "id2", sortId: 2),
        (image: Image(title: "image1", flickr: nil), searchId: "id1", sortId: 1), (image: Image(title: "image2", flickr: nil), searchId: "id1", sortId: 2)
    ]
    
    static let syncQueue = DispatchQueue(label: "ImageCachingServiceTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        var cachedImages: [(image: Image, searchId: String, sortId: Int)] = []
        
        init(cachedImages: [(image: Image, searchId: String, sortId: Int)] = []) {
            if !cachedImages.isEmpty {
                self.cachedImages = cachedImages
            }
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult {
            ImageCachingServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return .success(Data())
        }
        
        func prepareImages(_ imageData: Data?) async -> [Image]? {
            ImageCachingServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return try? JSONDecoder().decode([Image].self, from: imageData ?? Data())
        }
        
        func getImage(url: URL) async -> Data? {
            ImageCachingServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImageCachingServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
                cachedImages.append((image, searchId, sortId))
            }
            return nil
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            ImageCachingServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            var images: [ImageType] = []
            for image in cachedImages {
                if image.searchId == searchId {
                    ImageCachingServiceTests.syncQueue.sync {
                        images.append(image.image)
                    }
                }
            }
            ImageCachingServiceTests.syncQueue.sync {}
            return images
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImageCachingServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            for image in cachedImages {
                if image.searchId == searchId {
                    return true
                }
            }
            return false
        }
        
        // Called once when initializing the ImageCachingService to clear the Image table
        func deleteAllImages() async {}
    }
    
    func testCacheIfNecessaryUseCase_whenThumbnailsAreNil() async {
        var completionCallsCount = 0
        var precessedData: [ImageSearchResults] = []
        
        let imageRepository = ImageRepositoryMock()
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        await imageCachingService.didProcess.subscribe(self) { newData in
            completionCallsCount += 1
            precessedData = newData
        }
        
        let _ = await imageCachingService.cacheIfNecessary(ImageCachingServiceTests.searchResultsStub)
        
        XCTAssertEqual(completionCallsCount, 1)
        XCTAssertEqual(precessedData.count, 5)
        ImageCachingServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
            XCTAssertEqual(imageRepository.cachedImages.count, 0)
        }
    }
    
    func testCacheIfNecessaryUseCase_whenThumbnailsAreNotNil() async {
        var completionCallsCount = 0
        var precessedData: [ImageSearchResults] = []
        
        let imageRepository = ImageRepositoryMock()
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        await imageCachingService.didProcess.subscribe(self) { newData in
            completionCallsCount += 1
            precessedData = newData
        }
        
        let image1 = Image(title: "image1", flickr: nil)
        image1.thumbnail = ImageWrapper(image: UIImage())
        let image2 = Image(title: "image2", flickr: nil)
        image2.thumbnail = ImageWrapper(image: UIImage())
        let image3 = Image(title: "image3", flickr: nil)
        image3.thumbnail = ImageWrapper(image: UIImage())
        let image4 = Image(title: "image4", flickr: nil)
        image4.thumbnail = ImageWrapper(image: UIImage())
        let testSearchResults = [
            ImageSearchResults(id: "id5", searchQuery: ImageQuery(query: "query5"), searchResults: [image1, image2, image3, image4]),
            ImageSearchResults(id: "id4", searchQuery: ImageQuery(query: "query4"), searchResults: [image1, image2, image3, image4]),
            ImageSearchResults(id: "id3", searchQuery: ImageQuery(query: "query3"), searchResults: [image1, image2, image3]),
            ImageSearchResults(id: "id2", searchQuery: ImageQuery(query: "query2"), searchResults: [image1, image2]),
            ImageSearchResults(id: "id1", searchQuery: ImageQuery(query: "query1"), searchResults: [image1, image2])
        ]
        
        let _ = await imageCachingService.cacheIfNecessary(testSearchResults)
        
        XCTAssertEqual(completionCallsCount, 1)
        ImageCachingServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 6) // checkImagesAreCached(), saveImage() 2 times, checkImagesAreCached(), and saveImage() 2 times
        }
        XCTAssertEqual(precessedData.count, 5)
        for image in precessedData[3].searchResults {
            XCTAssertNil(image.thumbnail) // thumbnails of the 2nd search have been cleared from memory
        }
        for image in precessedData[4].searchResults {
            XCTAssertNil(image.thumbnail) // thumbnails of the 1st search have been cleared from memory
        }
        ImageCachingServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.cachedImages.count, 4) // 2 images of the 1st search and 2 images of the 2nd search in ImageCachingServiceTests.searchResultsStub have been cached
        }
    }
    
    func testGetCachedImagesUseCase_whenThereAreNoCachedImages() async {
        let imageRepository = ImageRepositoryMock()
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        
        let retrievedImagesFromCache = await imageCachingService.getCachedImages(searchId: "id2")
        
        XCTAssertNotNil(retrievedImagesFromCache)
        ImageCachingServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 1) // getImages()
        }
        let count = await imageCachingService.searchIdsToGetFromCache.count
        XCTAssertEqual(count, 1)
        XCTAssertEqual(retrievedImagesFromCache!.count, 0)
    }
    
    func testGetCachedImagesUseCase_whenThereAreCachedImages() async {
        let imageRepository = ImageRepositoryMock(cachedImages: ImageCachingServiceTests.cachedImagesStub)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        
        let retrievedImagesFromCache = await imageCachingService.getCachedImages(searchId: "id2")
        
        XCTAssertNotNil(retrievedImagesFromCache)
        ImageCachingServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 1) // getImages()
        }
        let count = await imageCachingService.searchIdsToGetFromCache.count
        XCTAssertEqual(count, 1)
        XCTAssertEqual(retrievedImagesFromCache!.count, 2)
    }
}
