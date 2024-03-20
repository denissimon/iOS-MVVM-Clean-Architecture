//
//  ImageServiceTests.swift
//  ImageSearchTests
//
//  Created by Denis Simon on 03/19/2024.
//

import XCTest
@testable import ImageSearch

class ImageServiceTests: XCTestCase {
    
    static let imagesStub = [
        Image(title: "random1", flickr: FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1")),
        Image(title: "random2", flickr: FlickrImageParameters(imageID: "id2", farm: 1, server: "server", secret: "secret2")),
        Image(title: "random3", flickr: FlickrImageParameters(imageID: "id3", farm: 1, server: "server", secret: "secret3"))
    ]
    
    static var testImageStub: Image {
        let testImage = Image(title: "random1", flickr: FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage.thumbnail = ImageWrapper(image: UIImage(systemName: "heart.fill"))
        return testImage
    }
    
    class ImageRepositoryMock: ImageRepository {
        
        let result: Result<Data, NetworkError>?
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        init(result: Result<Data, NetworkError>? = nil) {
            self.result = result
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult {
            apiMethodsCallsCount += 1
            return result!
        }
        
        func prepareImages(_ imageData: Data) async -> [Image]? {
            apiMethodsCallsCount += 1
            return try? JSONDecoder().decode([Image].self, from: imageData)
        }
        
        func getImage(url: URL) async -> Data? {
            apiMethodsCallsCount += 1
            let image = UIImage(systemName: "heart.fill")
            return image?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            dbMethodsCallsCount += 1
            return nil
        }
        
        func getImages(searchId: String) async -> [Image]? {
            dbMethodsCallsCount += 1
            return nil
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            dbMethodsCallsCount += 1
            return nil
        }
        
        func deleteAllImages() async {
            dbMethodsCallsCount += 1
        }
    }
    
    func testSearchImagesUseCase_whenResultIsSuccess() async throws {
        guard let imagesData = try? JSONEncoder().encode(ImageServiceTests.imagesStub) else {
            XCTFail()
            return
        }
        let imageRepository = ImageRepositoryMock(result: .success(imagesData))
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")
        let images = try? await imageService.searchImages(imageQuery)
        
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 3)
        XCTAssertTrue(images!.contains(ImageServiceTests.testImageStub))
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 5) // searchImages(), prepareImages(), and getImage() 3 times
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
    }
    
    func testSearchImagesUseCase_whenResultIsFailure() async throws {
        let imageRepository = ImageRepositoryMock(result: .failure(NetworkError(error: nil, code: nil)))
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")
        let images = try? await imageService.searchImages(imageQuery)
        
        XCTAssertNil(images)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // searchImages()
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
    }
    
    func testGetBigImageUseCase() async {
        let imageRepository = ImageRepositoryMock()
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        let bigImageData = await imageService.getBigImage(for: ImageServiceTests.testImageStub)
        
        XCTAssertNotNil(bigImageData)
        XCTAssertTrue(!bigImageData!.isEmpty)
        XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // getImage()
        XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
    }
}
