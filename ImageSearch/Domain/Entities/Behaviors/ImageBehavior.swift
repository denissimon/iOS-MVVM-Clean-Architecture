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
        let resultImage = deepCopy(image)
        switch size {
        case .thumbnail:
            resultImage.thumbnail = newWrapper
        case .big:
            resultImage.bigImage = newWrapper
        }
        return resultImage
    }
    
    // Another way to make a deep copy is to use DeepCopier.copy(of:)
    static func deepCopy(_ image: Image) -> Image {
        var thumbnail: ImageWrapper?
        if image.thumbnail != nil {
            thumbnail = ImageWrapper(uiImage: image.thumbnail!.uiImage)
        }
        var bigImage: ImageWrapper?
        if image.bigImage != nil {
            bigImage = ImageWrapper(uiImage: image.bigImage!.uiImage)
        }
        let newImage = Image(title: image.title, flickr: image.flickr)
        newImage.thumbnail = thumbnail
        newImage.bigImage = bigImage
        return newImage
    }
}
