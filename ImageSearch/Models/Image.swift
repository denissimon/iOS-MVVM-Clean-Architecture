//
//  Image.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit

class Image {
    
    var thumbnail: UIImage?
    var largeImage: UIImage?
    let imageID: String
    let farm: Int
    let server: String
    let secret: String
    
    init (imageID: String, farm: Int, server: String, secret: String) {
        self.imageID = imageID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    func getImageURL(_ size: String = "m") -> URL? {
        if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(imageID)_\(secret)_\(size).jpg") {
          return url
        }
        return nil
    }
}
