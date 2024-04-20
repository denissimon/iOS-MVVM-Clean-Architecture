import XCTest
@testable import ImageSearch

class ImageDetailsViewModelTests: XCTestCase {
    
    var imageDetailsViewModel: ImageDetailsViewModel!
    
    var observablesTriggerCount = 0
    
    static var testImageStub: Image {
        let testImage = Image(title: "random1", flickr: FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage.thumbnail = ImageWrapper(image: UIImage(systemName: "heart.fill"))
        testImage.bigImage = nil
        return testImage
    }
    
    static let syncQueue = DispatchQueue(label: "ImageDetailsViewModelTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult {
            ImageDetailsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return .success(Data())
        }
        
        func prepareImages(_ imageData: Data?) async -> [Image]? {
            ImageDetailsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return try? JSONDecoder().decode([Image].self, from: imageData ?? Data())
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
            return nil
        }
        
        func getImages(searchId: String) async -> [Image]? {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
            return nil
        }
        
        func deleteAllImages() async {
            ImageDetailsViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        
        let imageRepository = ImageRepositoryMock()
        let imageService = DefaultImageService(imageRepository: imageRepository)
        
        imageDetailsViewModel = DefaultImageDetailsViewModel(imageService: imageService, image: ImageDetailsViewModelTests.testImageStub, imageQuery: ImageQuery(query: "random"))
        
        imageDetailsViewModel.data.bind(self) { [weak self] _ in
            ImageDetailsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        
        imageDetailsViewModel.showToast.bind(self) { [weak self] _ in
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
        XCTAssertNil(self.imageDetailsViewModel.image.bigImage)
        XCTAssertNil(self.imageDetailsViewModel.data.value)
        
        imageDetailsViewModel.loadBigImage()
        
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        
        XCTAssertNotNil(self.imageDetailsViewModel.image.bigImage)
        XCTAssertNotNil(self.imageDetailsViewModel.data.value)
        XCTAssertNotNil(self.imageDetailsViewModel.data.value?.image)
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 3) // activityIndicatorVisibility, data, activityIndicatorVisibility
        }
    }
    
    func testGetTitle() {
        let title = imageDetailsViewModel.getTitle()
        
        XCTAssertEqual(title, "random")
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 0)
        }
    }
    
    func testSharedImage() async throws {
        imageDetailsViewModel.onShareButton()
        XCTAssertTrue(self.imageDetailsViewModel.shareImage.value.isEmpty)
        XCTAssertEqual(self.imageDetailsViewModel.showToast.value, "No image to share")
        
        imageDetailsViewModel.loadBigImage()
        
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        
        self.imageDetailsViewModel.onShareButton()
        XCTAssertFalse(self.imageDetailsViewModel.shareImage.value.isEmpty)
        
        ImageDetailsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 5) // showToast, activityIndicatorVisibility, data, activityIndicatorVisibility, shareImage
        }
    }
}
