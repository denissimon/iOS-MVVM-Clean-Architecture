import Foundation

// Delegated behavior of Image entity
class ImageBehavior {
    
    static func getFlickrImageURL(_ image: Image, size: ImageSize) -> URL? {
        guard let flickrParams = image.flickr else { return nil }
        if let url = URL(string: "https://farm\(flickrParams.farm).staticflickr.com/\(flickrParams.server)/\(flickrParams.imageID)_\(flickrParams.secret)_\(size.rawValue).jpg") {
            return url
        }
        return nil
    }
    
    static func updateImage(_ image: Image, newWrapper: ImageWrapper?, for size: ImageSize) -> Image {
        let resultImage = image.copy()
        switch size {
        case .thumbnail:
            resultImage.thumbnail = newWrapper
        case .big:
            resultImage.bigImage = newWrapper
        }
        return resultImage
    }
}
