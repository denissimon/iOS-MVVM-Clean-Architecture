//
//  AppConstants.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation
import UAObfuscatedString

struct AppConstants {
    
    struct Storyboard {
        static let ImageSearchVCIdentifier = "imageSearchViewController"
        static let ImageDetailsVCIdentifier = "imageDetailsViewController"
    }
    
    struct FlickrAPI {
        // "8ca55bca1384f45ab957b7618afc6ecc"
        static let ApiKey = ""._8.c.a._5._5.b.c.a._1._3._8._4.f._4._5.a.b._9._5._7.b._7._6._1._8.a.f.c._6.e.c.c
        static let PhotosPerRequest = 20 // up to 20 photos
        static let BaseURL = "https://api.flickr.com/services/"
        static let HotListCount = 30 // up to 30 trending tags
    }
    
    struct ImageCollection {
        static let ItemsPerRow: Float = 2
        static let BaseImageWidth: Float = 240
        static let ReuseHeaderIdentifier = "CollectionViewHeader"
        static let ReuseCellIdentifier = "CollectionViewCell"
        static let VerticleSpace: Float = 35
        static let HorizontalSpace: Float = 20
    }
}
