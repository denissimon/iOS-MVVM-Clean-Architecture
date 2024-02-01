//
//  Image.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

// Note: in case of using SwiftUI, it's better to change the name of Image class to e.g. ISImage

import Foundation

struct FlickrParameters: Codable {
    let imageID: String
    let farm: Int
    let server: String
    let secret: String
}

class Image: Codable {
    
    var thumbnail: ImageWrapper?
    var bigImage: ImageWrapper?
    let title: String
    let flickr: FlickrParameters?
    
    init(title: String, flickr: FlickrParameters? = nil) {
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
        let flickr = FlickrParameters(imageID: imageID, farm: farm, server: server, secret: secret)
        self.init(title: title, flickr: flickr)
    }
}

enum ImageSize: String {
    case thumbnail = "m"
    case big = "b"
}
