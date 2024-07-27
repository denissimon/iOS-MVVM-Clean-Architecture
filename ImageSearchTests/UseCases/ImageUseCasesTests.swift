import XCTest
@testable import ImageSearch

class ImageUseCasesTests: XCTestCase {
    
    static let imagesStub = [
        Image(title: "random1", flickr: FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1")),
        Image(title: "random2", flickr: FlickrImageParameters(imageID: "id2", farm: 1, server: "server", secret: "secret2")),
        Image(title: "random3", flickr: FlickrImageParameters(imageID: "id3", farm: 1, server: "server", secret: "secret3"))
    ]
    
    static var testImageStub: Image {
        let testImage = Image(title: "random1", flickr: FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage.thumbnail = ImageWrapper(uiImage: UIImage(systemName: "heart.fill"))
        return testImage
    }
    
    static let syncQueue = DispatchQueue(label: "ImageUseCasesTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        let result: Result<Data?, AppError>?
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        init(result: Result<Data?, AppError>? = nil) {
            self.result = result
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> Result<Data?, AppError> {
            ImageUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result!
        }
        
        func prepareImages(_ imageData: Data?) async -> [Image]? {
            ImageUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return try? JSONDecoder().decode([Image].self, from: imageData ?? Data())
        }
        
        func getImage(url: URL) async -> Data? {
            ImageUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImageUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            ImageUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImageUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        // Called once when initializing the ImageCachingService to clear the Image table
        func deleteAllImages() async {}
    }
    
    func testSearchImagesUseCase_whenResultIsSuccess() async {
        guard let imagesData = try? JSONEncoder().encode(ImageUseCasesTests.imagesStub) else {
            XCTFail()
            return
        }
        let imageRepository = ImageRepositoryMock(result: .success(imagesData))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")
        let result = try? await searchImagesUseCase.execute(imageQuery)
        
        XCTAssertNotNil(result)
        let images = result!.searchResults
        XCTAssertEqual(images.count, 3)
        XCTAssertTrue(images.contains(ImageUseCasesTests.testImageStub))
        ImageUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 5) // searchImages(), prepareImages(), and getImage() 3 times
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    func testSearchImagesUseCase_whenResultIsFailure() async {
        let imageRepository = ImageRepositoryMock(result: .failure(AppError.default()))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")
        let result = try? await searchImagesUseCase.execute(imageQuery)
        
        XCTAssertNil(result)
        ImageUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // searchImages()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    func testGetBigImageUseCase() async {
        let imageRepository = ImageRepositoryMock()
        let getBigImageUseCase = DefaultGetBigImageUseCase(imageRepository: imageRepository)
        
        let bigImageData = await getBigImageUseCase.execute(for: ImageUseCasesTests.testImageStub)
        
        XCTAssertNotNil(bigImageData)
        XCTAssertTrue(!bigImageData!.isEmpty)
        if let expectedImageData = UIImage(systemName: "heart.fill")?.pngData() {
            XCTAssertEqual(bigImageData, expectedImageData)
        }
        ImageUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // getImage()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
}
