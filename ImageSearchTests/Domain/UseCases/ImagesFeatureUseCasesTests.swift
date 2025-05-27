import XCTest
@testable import ImageSearch

class ImagesFeatureUseCasesTests: XCTestCase {
    
    static let imagesStub = [
        Image(title: "random1", flickr: Image.FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1")),
        Image(title: "random2", flickr: Image.FlickrImageParameters(imageID: "id2", farm: 1, server: "server", secret: "secret2")),
        Image(title: "random3", flickr: Image.FlickrImageParameters(imageID: "id3", farm: 1, server: "server", secret: "secret3"))
    ]
    
    static var testImageStub: Image {
        var testImage = Image(title: "random1", flickr: Image.FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage = ImageBehavior.updateImage(testImage, newWrapper: ImageWrapper(uiImage: UIImage(systemName: "heart.fill")), for: .thumbnail)
        return testImage
    }
    
    static let imagesDataStub = """
        {"photos":{"page":1,"pages":5632,"perpage":2,"total":112631,"photo":[{"id":"53910549451","owner":"183377981@N03","secret":"e5d42720cb","server":"65535","farm":66,"title":"Bees at rest","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53910928365","owner":"44904157@N04","secret":"1b80873d60","server":"65535","farm":66,"title":"Wagon Load of Flowers","ispublic":1,"isfriend":0,"isfamily":0}]},"stat":"ok"}
        """.data(using: .utf8)
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2")]),
        stat: "ok")
    
    static let syncQueue = DispatchQueue(label: "ImagesFeatureUseCasesTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        let result: Result<[ImageType], CustomError>?
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        init(result: Result<[ImageType], CustomError>? = nil) {
            self.result = result
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> Result<[ImageType], CustomError> {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result!
        }
        
        func getImage(url: URL) async -> Data? {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return true
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return []
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        // Called once when initializing the ImageCachingService to clear the Image table
        func deleteAllImages() async {}
    }
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<TagsType, CustomError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<TagsType, CustomError>) {
            self.result = result
        }
        
        func getHotTags() async -> Result<TagsType, CustomError> {
            ImagesFeatureUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result
        }
    }
    
    // MARK: - SearchImagesUseCase
    
    func testSearchImagesUseCase_whenResultIsSuccess() async {
        let imageRepository = ImageRepositoryMock(result: .success(ImagesFeatureUseCasesTests.imagesStub))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")!
        let result = await searchImagesUseCase.execute(imageQuery)
        let images = (try? result.get())?.searchResults
        
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 3)
        XCTAssertTrue(images!.contains(ImagesFeatureUseCasesTests.testImageStub))
        
        ImagesFeatureUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 4) // searchImages(), and getImage() 3 times
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    func testPrepareImages() async {
        let diContainer = DIContainer()
        let imageRepository = DefaultImageRepository(apiInteractor: diContainer.apiInteractor, imageDBInteractor: diContainer.imageDBInteractor)
        
        let images = imageRepository.toTestPrepareImages(ImagesFeatureUseCasesTests.imagesDataStub)
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 2)
        XCTAssertEqual(images![0].flickr?.imageID, "53910549451")
        XCTAssertEqual(images![1].flickr?.imageID, "53910928365")
    }
    
    func testSearchImagesUseCase_whenResultIsFailure() async {
        let imageRepository = ImageRepositoryMock(result: .failure(CustomError.internetConnection()))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        
        let imageQuery = ImageQuery(query: "random")!
        let result = await searchImagesUseCase.execute(imageQuery)
        let images = (try? result.get())?.searchResults
        
        XCTAssertNil(images)
        
        ImagesFeatureUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // searchImages()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    // MARK: - GetBigImageUseCase
    
    func testGetBigImageUseCase() async {
        let imageRepository = ImageRepositoryMock()
        let getBigImageUseCase = DefaultGetBigImageUseCase(imageRepository: imageRepository)
        
        let bigImageData = await getBigImageUseCase.execute(for: ImagesFeatureUseCasesTests.testImageStub)
        
        XCTAssertNotNil(bigImageData)
        XCTAssertTrue(!bigImageData!.isEmpty)
        if let expectedImageData = UIImage(systemName: "heart.fill")?.pngData() {
            XCTAssertEqual(bigImageData, expectedImageData)
        }
        ImagesFeatureUseCasesTests.syncQueue.sync {
            XCTAssertEqual(imageRepository.apiMethodsCallsCount, 1) // getImage()
            XCTAssertEqual(imageRepository.dbMethodsCallsCount, 0)
        }
    }
    
    // MARK: - GetHotTagsUseCase
    
    func testGetHotTagsUseCase_whenResultIsSuccess() async {
        let tagRepository = TagRepositoryMock(result: .success(ImagesFeatureUseCasesTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        
        let tagsResult = await getHotTagsUseCase.execute()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNotNil(hotTags)
        XCTAssertEqual(hotTags!.count, 2)
        ImagesFeatureUseCasesTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsFailure() async {
        let tagRepository = TagRepositoryMock(result: .failure(CustomError.internetConnection()))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        
        let tagsResult = await getHotTagsUseCase.execute()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNil(hotTags)
        ImagesFeatureUseCasesTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
}
