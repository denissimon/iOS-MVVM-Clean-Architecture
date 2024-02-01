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
    
    init?(from: [String : AnyObject]) {
        guard let imageID = from["id"] as? String,
              let farm = from["farm"] as? Int,
              let server = from["server"] as? String,
              let secret = from["secret"] as? String,
              let title = from["title"] as? String else {
                  return nil
              }
        self.imageID = imageID
        self.farm = farm
        self.server = server
        self.secret = secret
        self.title = title
    }
}

enum ImageSize: String {
    case thumbnail = "m"
    case big = "b"
}
