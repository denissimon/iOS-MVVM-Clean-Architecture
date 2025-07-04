import XCTest
@testable import ImageSearch

class ImageSearchViewModelTests: XCTestCase {
    
    var observablesTriggerCount = 0
    
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
    
    static let searchResultsStub = [
        ImageSearchResults(id: "id5", searchQuery: ImageQuery(query: "query5")!, searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil), Image(title: "image4", flickr: nil)]),
        ImageSearchResults(id: "id4", searchQuery: ImageQuery(query: "query4")!, searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil), Image(title: "image4", flickr: nil)]),
        ImageSearchResults(id: "id3", searchQuery: ImageQuery(query: "query3")!, searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil), Image(title: "image3", flickr: nil)]),
        ImageSearchResults(id: "id2", searchQuery: ImageQuery(query: "query2")!, searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil)]),
        ImageSearchResults(id: "id1", searchQuery: ImageQuery(query: "query1")!, searchResults: [Image(title: "image1", flickr: nil), Image(title: "image2", flickr: nil)])
    ]
    
    static let cachedImagesStub = [
        (image: Image(title: "image1", flickr: nil), searchId: "id2", sortId: 1), (image: Image(title: "image2", flickr: nil), searchId: "id2", sortId: 2),
        (image: Image(title: "image1", flickr: nil), searchId: "id1", sortId: 1), (image: Image(title: "image2", flickr: nil), searchId: "id1", sortId: 2)
    ]
    
    static let syncQueue = DispatchQueue(label: "ImageSearchViewModelTests")
    
    class ImageRepositoryMock: ImageRepository {
        
        let response: Result<[ImageType], CustomError>
        var cachedImages: [(image: Image, searchId: String, sortId: Int)] = []
        var apiMethodsCallsCount = 0
        var dbMethodsCallsCount = 0
        
        init(response: Result<[ImageType], CustomError>, cachedImages: [(image: Image, searchId: String, sortId: Int)] = []) {
            self.response = response
            if !cachedImages.isEmpty {
                self.cachedImages = cachedImages
            }
        }
        
        // API methods
        
        func searchImages(_ imageQuery: ImageQuery) async -> Result<[ImageType], CustomError> {
            ImageSearchViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return response
        }
        
        func getImage(url: URL) async -> Data? {
            ImageSearchViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return UIImage(systemName: "heart.fill")?.pngData()
        }
        
        // DB methods
        
        func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
            ImageSearchViewModelTests.syncQueue.sync {
                dbMethodsCallsCount += 1
                cachedImages.append((image, searchId, sortId))
            }
            return true
        }
        
        func getImages(searchId: String) async -> [ImageType]? {
            var images: [ImageType] = []
            ImageCachingServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
                for image in cachedImages {
                    if image.searchId == searchId {
                        images.append(image.image)
                    }
                }
            }
            return images
        }
        
        func checkImagesAreCached(searchId: String) async -> Bool? {
            var result: Bool = false
            ImageCachingServiceTests.syncQueue.sync {
                dbMethodsCallsCount += 1
                for image in cachedImages {
                    if image.searchId == searchId {
                        result = true
                    }
                }
            }
            return result
        }
        
        // Called once when initializing the ImageCachingService to clear the Image table
        func deleteAllImages() async {}
    }
    
    private func bind(_ imageSearchViewModel: ImageSearchViewModel) {
        imageSearchViewModel.data.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.sectionData.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.scrollTop.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.makeToast.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.resetSearchBar.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.activityIndicatorVisibility.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        imageSearchViewModel.collectionViewTopConstraint.bind(self) { [weak self] _ in
            ImageSearchViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
    }
    
    func testSearchImage_whenSearchQueryIsNotValid() {
        let imageRepository = ImageRepositoryMock(response: .success(ImageSearchViewModelTests.imagesStub))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        let imageSearchViewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        bind(imageSearchViewModel)
        
        imageSearchViewModel.searchImages(for: "")
        XCTAssertEqual(imageSearchViewModel.makeToast.value, NSLocalizedString("Search query error", comment: ""))
        XCTAssertTrue(imageSearchViewModel.data.value.isEmpty)
        
        imageSearchViewModel.searchImages(for: " ")
        XCTAssertEqual(imageSearchViewModel.makeToast.value, NSLocalizedString("Search query error", comment: ""))
        XCTAssertTrue(imageSearchViewModel.data.value.isEmpty)
        
        ImageSearchViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 4) // makeToast, resetSearchBar, makeToast, resetSearchBar
        }
    }
    
    func testSearchImage_whenSearchQueryIsValid_andWhenResultIsSuccess() async throws {
        let imageRepository = ImageRepositoryMock(response: .success(ImageSearchViewModelTests.imagesStub))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        let imageSearchViewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        bind(imageSearchViewModel)
        
        XCTAssertEqual(imageSearchViewModel.data.value.count, 0)
        
        let query = "random"
        imageSearchViewModel.searchImages(for: query)
        XCTAssertEqual(imageSearchViewModel.makeToast.value, "")
        await imageSearchViewModel.toTestImagesLoadTask?.value
        
        XCTAssertEqual(imageSearchViewModel.data.value.count, 1)
        XCTAssertTrue((imageSearchViewModel.data.value[0]._searchResults as! [Image]).contains(ImageSearchViewModelTests.testImageStub))
        if let expectedImageData = UIImage(systemName: "heart.fill")?.pngData() {
            XCTAssertEqual((imageSearchViewModel.data.value[0]._searchResults as! [Image])[0].thumbnail?.uiImage?.pngData(), Supportive.toUIImage(from: expectedImageData)?.pngData())
        }
        XCTAssertEqual(imageSearchViewModel.lastQuery?.query, query)
        ImageSearchViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 4) // activityIndicatorVisibility, data, activityIndicatorVisibility, scrollTop
        }
    }
    
    func testSearchImage_whenSearchQueryIsValid_andWhenResultIsFailure() async throws {
        let imageRepository = ImageRepositoryMock(response: .failure(CustomError.internetConnection()))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        let imageSearchViewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        bind(imageSearchViewModel)
        
        XCTAssertTrue(imageSearchViewModel.data.value.isEmpty)
        
        imageSearchViewModel.searchImages(for: "random")
        XCTAssertEqual(imageSearchViewModel.makeToast.value, "")
        await imageSearchViewModel.toTestImagesLoadTask?.value
        
        XCTAssertTrue(imageSearchViewModel.data.value.isEmpty)
        XCTAssertNil(imageSearchViewModel.lastQuery)
        ImageSearchViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 3) // activityIndicatorVisibility, makeToast, activityIndicatorVisibility
        }
    }
    
    func testSearchImage_whenSearchIsRunTwice() async throws {
        let imageRepository = ImageRepositoryMock(response: .success(ImageSearchViewModelTests.imagesStub))
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        let imageSearchViewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        bind(imageSearchViewModel)
        
        XCTAssertEqual(imageSearchViewModel.data.value.count, 0)
        
        imageSearchViewModel.searchImages(for: "query")
        await imageSearchViewModel.toTestImagesLoadTask?.value
        
        XCTAssertEqual(imageSearchViewModel.data.value.count, 1)
        
        let query1 = "query1"
        imageSearchViewModel.searchImages(for: query1)
        await imageSearchViewModel.toTestImagesLoadTask?.value
        
        XCTAssertEqual(imageSearchViewModel.data.value.count, 2)
        XCTAssertTrue((imageSearchViewModel.data.value[0]._searchResults as! [Image]).contains(ImageSearchViewModelTests.testImageStub))
        XCTAssertTrue((imageSearchViewModel.data.value[1]._searchResults as! [Image]).contains(ImageSearchViewModelTests.testImageStub))
        XCTAssertEqual(imageSearchViewModel.lastQuery?.query, query1)
        ImageSearchViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 8) // activityIndicatorVisibility, data, activityIndicatorVisibility, scrollTop, activityIndicatorVisibility, data, activityIndicatorVisibility, scrollTop
        }
    }
    
    func testUpdateSection() async throws {
        var cachedImagesStub = ImageSearchViewModelTests.cachedImagesStub
        for (index, image) in cachedImagesStub.enumerated() {
            cachedImagesStub[index].image = ImageBehavior.updateImage(image.image, newWrapper: ImageWrapper(uiImage: UIImage(systemName: "heart.fill")), for: .thumbnail)
        }
        
        let imageRepository = ImageRepositoryMock(response: .success(ImageSearchViewModelTests.imagesStub), cachedImages: cachedImagesStub)
        let searchImagesUseCase = DefaultSearchImagesUseCase(imageRepository: imageRepository)
        let imageCachingService = DefaultImageCachingService(imageRepository: imageRepository)
        let imageSearchViewModel = DefaultImageSearchViewModel(searchImagesUseCase: searchImagesUseCase, imageCachingService: imageCachingService)
        bind(imageSearchViewModel)
        
        imageSearchViewModel.data.value = ImageSearchViewModelTests.searchResultsStub // 5 searches are done
        XCTAssertEqual(imageRepository.cachedImages.count, 4) // 2 images of the 1st search and 2 images of the 2nd search in ImageCachingServiceTests.searchResultsStub are cached
        for image in imageSearchViewModel.data.value[3]._searchResults {
            XCTAssertNil(image.thumbnail)
        }
        for image in imageSearchViewModel.data.value[4]._searchResults {
            XCTAssertNil(image.thumbnail)
        }
        
        // Get images of the 2nd search from cache and update data
        imageSearchViewModel.updateSection("id2")
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        for image in imageSearchViewModel.data.value[3]._searchResults {
            XCTAssertNotNil(image.thumbnail)
        }
        for image in imageSearchViewModel.data.value[4]._searchResults {
            XCTAssertNil(image.thumbnail)
        }
        
        // Get images of the 1st search from cache and update data
        imageSearchViewModel.updateSection("id1")
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        for image in imageSearchViewModel.data.value[3]._searchResults {
            XCTAssertNotNil(image.thumbnail)
        }
        for image in imageSearchViewModel.data.value[4]._searchResults {
            XCTAssertNotNil(image.thumbnail)
        }
        
        ImageSearchViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 3) // data, sectionData, sectionData
        }
    }
}
