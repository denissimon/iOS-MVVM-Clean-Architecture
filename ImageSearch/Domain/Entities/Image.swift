import Foundation

protocol ImageType {
    var thumbnail: ImageWrapper? { get set }
    var bigImage: ImageWrapper? { get set }
    var title: String { get }
}

protocol ImageListItemVM {
    var thumbnail: ImageWrapper? { get }
}

struct Image: Codable, ImageType, ImageListItemVM {
    
    struct FlickrImageParameters: Codable {
        let imageID: String
        let farm: Int
        let server: String
        let secret: String
    }
    
    var thumbnail: ImageWrapper?
    var bigImage: ImageWrapper?
    let title: String
    let flickr: FlickrImageParameters?
    
    init(title: String, flickr: FlickrImageParameters? = nil) {
        self.title = title
        self.flickr = flickr
    }
    
    init?(flickrParams: [String: AnyObject]) {
        guard let imageID = flickrParams["id"] as? String,
              let farm = flickrParams["farm"] as? Int,
              let server = flickrParams["server"] as? String,
              let secret = flickrParams["secret"] as? String,
              let title = flickrParams["title"] as? String else {
                  return nil
              }
        let flickr = FlickrImageParameters(imageID: imageID, farm: farm, server: server, secret: secret)
        self.init(title: title, flickr: flickr)
    }
}

extension Image: Equatable {
    static func == (lhs: Image, rhs: Image) -> Bool {
        if lhs.title == rhs.title &&
            lhs.flickr?.imageID == rhs.flickr?.imageID &&
            ((lhs.thumbnail != nil && rhs.thumbnail != nil) ||
                (lhs.thumbnail == nil && rhs.thumbnail == nil)) {
            return true
        }
        return false
    }
}

enum ImageSize: String {
    case thumbnail = "m"
    case big = "b"
}
