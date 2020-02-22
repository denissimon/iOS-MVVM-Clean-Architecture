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
    
    struct MainStoryboard {
        static let imageSearchVCIdentifier = "imageSearchViewController"
        static let imageDetailsVCIdentifier = "imageDetailsViewController"
    }
    
    struct API {
        // "8ca55bca1384f45ab957b7618afc6ecc"
        static let apiKey = ""._8.c.a._5._5.b.c.a._1._3._8._4.f._4._5.a.b._9._5._7.b._7._6._1._8.a.f.c._6.e.c.c
        static let photosPerRequest = 20 // up to 20
        static let baseUrl = "https://api.flickr.com/services/rest/"
    }
    
    struct ImageCollection {
        static let itemsPerRow: Float = 2
        static let baseImageWidth: Float = 240
        static let reuseHeaderIdentifier = "CollectionViewHeader"
        static let reuseCellIdentifier = "CollectionViewCell"
        static let verticleSpace: Float = 35
        static let horizontalSpace: Float = 20
    }
}
