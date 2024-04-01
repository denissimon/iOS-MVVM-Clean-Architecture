//
//  ImageCachingServiceTests.swift
//  ImageSearchTests
//
//  Created by Denis Simon on 03/19/2024.
//

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
            apiMethodsCallsCount += 1
            return .success(Data())
        }
        
        func prepareImages(_ imageData: Data) async -> [Image]? {
            apiMethodsCallsCount += 1
            return try? JSONDecoder().decode([Image].self, from: imageData)
        }
        
        func getImage(url: URL) async -> Data? {
            apiMethodsCallsCount += 1
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            dbMethodsCallsCount += 1
            cachedImages.append((image, searchId, sortId))
            return nil
        }
        
        func getImages(searchId: String) async -> [Image]? {
            dbMethodsCallsCount += 1
            var images: [Image] = []
            for image in cachedImages {
                if image.searchId == searchId {
                    images.append(image.image)
                }
            }
            return images
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            dbMethodsCallsCount += 1
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
        imageCachingService.didProcess.subscribe(self) { newData in
            completionCallsCount += 1
            precessedData = newData
        }
        
        let _ = await imageCachingService.cacheIfNecessary(ImageCachingServiceTests.searchResultsStub)
        
        XCTAssertEqual(completionCallsCount, 1)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        XCTAssertEqual(precessedData.count, 5)
        XCTAssertEqual(imageRepository.cachedImages.count, 0)
    }
    
    func testCacheIfNecessaryUseCase_whenThumbnailsAreNotNil() async {
        var completionCallsCount = 0
        var precessedData: [ImageSearchResults] = []
        
        let imageRepository = ImageRepositoryMock()
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        imageCachingService.didProcess.subscribe(self) { newData in
            completionCallsCount += 1
            precessedData = newData
        }
        
        let testSearchResults = ImageCachingServiceTests.searchResultsStub
        for image in testSearchResults[3].searchResults {
            image.thumbnail = ImageWrapper(image: UIImage())
        }
        for image in testSearchResults[4].searchResults {
            image.thumbnail = ImageWrapper(image: UIImage())
        }
        let _ = await imageCachingService.cacheIfNecessary(testSearchResults)
        
        XCTAssertEqual(completionCallsCount, 1)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 6) // checkImagesAreCached(), saveImage() 2 times, checkImagesAreCached(), and saveImage() 2 times
        XCTAssertEqual(precessedData.count, 5)
        for image in precessedData[3].searchResults {
            XCTAssertNil(image.thumbnail) // thumbnails of the 2nd search have been cleared from memory
        }
        for image in precessedData[4].searchResults {
            XCTAssertNil(image.thumbnail) // thumbnails of the 1st search have been cleared from memory
        }
        XCTAssertEqual(imageRepository.cachedImages.count, 4) // 2 images of the 1st search and 2 images of the 2nd search in ImageCachingServiceTests.searchResultsStub have been cached
    }
    
    func testGetCachedImagesUseCase_whenThereAreNoCachedImages() async {
        let imageRepository = ImageRepositoryMock()
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        
        let retrievedImagesFromCache = await imageCachingService.getCachedImages(searchId: "id2")
        
        XCTAssertNotNil(retrievedImagesFromCache)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 1) // getImages()
        XCTAssertEqual(imageCachingService.searchIdsToGetFromCache.count, 1)
        XCTAssertEqual(retrievedImagesFromCache!.count, 0)
    }
    
    func testGetCachedImagesUseCase_whenThereAreCachedImages() async {
        let imageRepository = ImageRepositoryMock(cachedImages: ImageCachingServiceTests.cachedImagesStub)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        
        let retrievedImagesFromCache = await imageCachingService.getCachedImages(searchId: "id2")
        
        XCTAssertNotNil(retrievedImagesFromCache)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 0)
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 1) // getImages()
        XCTAssertEqual(imageCachingService.searchIdsToGetFromCache.count, 1)
        XCTAssertEqual(retrievedImagesFromCache!.count, 2)
    }
}
