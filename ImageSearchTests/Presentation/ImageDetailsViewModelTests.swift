import XCTest
@testable import ImageSearch

class ImageDetailsViewModelTests: XCTestCase {
    
    var imageDetailsViewModel: ImageDetailsViewModel!
    
    var observablesTriggerCount = 0
    
    static var testImageStub: Image {
        let testImage = Image(title: "random1", flickr: Image.FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage.thumbnail = ImageWrapper(uiImage: UIImage(systemName: "heart.fill"))
        testImage.bigImage = nil
        return testImage
    }
    
    static let syncQueue = DispatchQueue(label: "ImageDetailsViewModelTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> Result<[ImageType], CustomError> {
            ImageDetailsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return .success([])
        }
        
        func getImage(url: URL) async -> Data? {
            ImageDetailsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return true
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return []
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        // Called once when initializing the ImageCachingService to clear the Image table
        func deleteAllImages() async {}
    }
    
    override func setUp() {
        super.setUp()
        
        let imageRepository = ImageRepositoryMock()
        let getBigImageUseCase = DefaultGetBigImageUseCase(imageRepository: imageRepository)
        
        imageDetailsViewModel = DefaultImageDetailsViewModel(getBigImageUseCase: getBigImageUseCase, image: ImageDetailsViewModelTests.testImageStub, imageQuery: ImageQuery(query: "random"))
        
        imageDetailsViewModel.data.bind(self) { [weak self] _ in
            ImageDetailsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        
        imageDetailsViewModel.makeToast.bind(self) { [weak self] _ in
            ImageDetailsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        
        imageDetailsViewModel.shareImage.bind(self) { [weak self] _ in
            ImageDetailsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        
        imageDetailsViewModel.activityIndicatorVisibility.bind(self) { [weak self] _ in
            ImageDetailsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
    }

    override func tearDown() {
        super.tearDown()
        ImageDetailsViewModelTests.syncQueue.sync {
            imageDetailsViewModel = nil
        }
    }
    
    func testLoadBigImage() async throws {
        XCTAssertNil(imageDetailsViewModel.image.bigImage)
        XCTAssertNil(imageDetailsViewModel.data.value)
        
        imageDetailsViewModel.loadBigImage()
        await (imageDetailsViewModel as! DefaultImageDetailsViewModel).toTestImageLoadTask?.value
        
        XCTAssertNotNil(imageDetailsViewModel.image.bigImage)
        XCTAssertNotNil(imageDetailsViewModel.data.value)
        XCTAssertNotNil(imageDetailsViewModel.data.value?.uiImage)
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 3) // activityIndicatorVisibility, data, activityIndicatorVisibility
        }
    }
    
    func testGetTitle() {
        let title = imageDetailsViewModel.getTitle()
        
        XCTAssertEqual(title, "random")
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 0)
        }
    }
    
    func testSharedImage() async throws {
        imageDetailsViewModel.onShareButton()
        XCTAssertTrue(imageDetailsViewModel.shareImage.value.isEmpty)
        XCTAssertEqual(imageDetailsViewModel.makeToast.value, NSLocalizedString("No image to share", comment: ""))
        
        imageDetailsViewModel.loadBigImage()
        await (imageDetailsViewModel as! DefaultImageDetailsViewModel).toTestImageLoadTask?.value
        
        imageDetailsViewModel.onShareButton()
        XCTAssertFalse(imageDetailsViewModel.shareImage.value.isEmpty)
        
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 5) // makeToast, activityIndicatorVisibility, data, activityIndicatorVisibility, shareImage
        }
    }
}
