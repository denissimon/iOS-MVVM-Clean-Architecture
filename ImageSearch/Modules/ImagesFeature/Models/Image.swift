//
//  Image.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

class Image: Codable {
    var thumbnail: ImageWrapper?
    var bigImage: ImageWrapper?
    let imageID: String
    let farm: Int
    let server: String
    let secret: String
    let title: String
    
    init (imageID: String, farm: Int, server: String, secret: String, title: String) {
        self.imageID = imageID
        self.farm = farm
        self.server = server
        self.secret = secret
        self.title = title
    }
    
    func getImageURL(_ size: ImageSize = .medium) -> URL? {
        if let url = URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(imageID)_\(secret)_\(size.rawValue).jpg") {
          return url
        }
        return nil
    }
}

struct Images {
    let data: [Image]
}

enum ImageSize: String {
    case small = "s"
    case medium = "m"
    case big = "b"
}
