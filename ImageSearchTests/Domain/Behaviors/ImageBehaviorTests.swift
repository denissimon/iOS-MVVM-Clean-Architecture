import XCTest
@testable import ImageSearch

class ImageBehaviorTests: XCTestCase {
    
    static var testImageStub: Image {
        var testImage = Image(title: "random1", flickr: Image.FlickrImageParameters(imageID: "id1", farm: 1, server: "server", secret: "secret1"))
        testImage = ImageBehavior.updateImage(testImage, newWrapper: ImageWrapper(uiImage: UIImage(systemName: "heart.fill")), for: .thumbnail)
        return testImage
    }
    
    func testGetFlickrImageURL() {
        let thumbnailUrl = ImageBehavior.getFlickrImageURL(ImageBehaviorTests.testImageStub, size: .thumbnail)
        
        XCTAssertNotNil(thumbnailUrl)
        XCTAssertEqual(thumbnailUrl!.description, "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")
        
        let bigImageURL = ImageBehavior.getFlickrImageURL(ImageBehaviorTests.testImageStub, size: .big)
        
        XCTAssertNotNil(bigImageURL)
        XCTAssertEqual(bigImageURL!.description, "https://farm1.staticflickr.com/server/id1_secret1_b.jpg")
    }
    
    func testUpdateImage() {
        var image = ImageBehaviorTests.testImageStub
        XCTAssertNil(image.bigImage)
        
        let imageWrapper = ImageWrapper(uiImage: UIImage(systemName: "square.and.arrow.up"))
        image = ImageBehavior.updateImage(image, newWrapper: imageWrapper, for: .big)
        XCTAssertNotNil(image.bigImage)
        
        image = ImageBehavior.updateImage(image, newWrapper: nil, for: .big)
        XCTAssertNil(image.bigImage)
        
        XCTAssertNotNil(image.thumbnail)
        image = ImageBehavior.updateImage(image, newWrapper: nil, for: .thumbnail)
        XCTAssertNil(image.thumbnail)
    }
}
