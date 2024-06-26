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
    
    static let syncQueue = DispatchQueue(label: "ImageServiceTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        let result: Result<Data?, AppError>?
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        init(result: Result<Data?, AppError>? = nil) {
            self.result = result
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult {
            ImageServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result!
        }
        
        func prepareImages(_ imageData: Data?) async -> [Image]? {
            ImageServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return try? JSONDecoder().decode([Image].self, from: imageData ?? Data())
        }
        
        func getImage(url: URL) async -> Data? {
            ImageServiceTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImageServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            ImageServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImageServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func deleteAllImages() async {
            ImageServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
        }
    }
    
    func testSearchImagesUseCase_whenResultIsSuccess() async {
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
        ImageServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 5) // searchImages(), prepareImages(), and getImage() 3 times
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    func testSearchImagesUseCase_whenResultIsFailure() async {
        let imageRepository = ImageRepositoryMock(result: .failure(AppError.default()))
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")
        let images = try? await imageService.searchImages(imageQuery)
        
        XCTAssertNil(images)
        ImageServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // searchImages()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    func testGetBigImageUseCase() async {
        let imageRepository = ImageRepositoryMock()
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        let bigImageData = await imageService.getBigImage(for: ImageServiceTests.testImageStub)
        
        XCTAssertNotNil(bigImageData)
        XCTAssertTrue(!bigImageData!.isEmpty)
        if let expectedImageData = UIImage(systemName: "heart.fill")?.pngData() {
            XCTAssertEqual(bigImageData, expectedImageData)
        }
        ImageServiceTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // getImage()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
}
