//
//  Image.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

// Note: in case of using SwiftUI, it's better to change the name of Image class to e.g. ISImage

import Foundation

struct FlickrImageParameters: Codable {
    let imageID: String
    let farm: Int
    let server: String
    let secret: String
}

class Image: Codable {
    
    var thumbnail: ImageWrapper?
    var bigImage: ImageWrapper?
    let title: String
    let flickr: FlickrImageParameters?
    
    init(title: String, flickr: FlickrImageParameters? = nil) {
        self.title = title
        self.flickr = flickr
    }
    
    convenience init?(flickrParams: [String : AnyObject]) {
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
    
    // Another way to make a deep copy is to use DeepCopier.copy(of:)
    func deepCopy() -> Image {
        var thumbnail: ImageWrapper?
        if self.thumbnail != nil {
            thumbnail = ImageWrapper(image: self.thumbnail!.image)
        }
        var bigImage: ImageWrapper?
        if self.bigImage != nil {
            bigImage = ImageWrapper(image: self.bigImage!.image)
        }
        let newImage = Image(title: self.title, flickr: flickr)
        newImage.thumbnail = thumbnail
        newImage.bigImage = bigImage
        return newImage
    }
}

enum ImageSize: String {
    case thumbnail = "m"
    case big = "b"
}
