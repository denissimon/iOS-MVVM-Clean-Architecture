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
    
    struct Storyboards {
        static let ImageSearchVCIdentifier = "imageSearchViewController"
        static let ImageDetailsVCIdentifier = "imageDetailsViewController"
        static let HotTagsListVCIdentifier = "hotTagsListViewController"
    }
    
    struct FlickrAPI {
        // "8ca55bca1384f45ab957b7618afc6ecc"
        static let ApiKey = ""._8.c.a._5._5.b.c.a._1._3._8._4.f._4._5.a.b._9._5._7.b._7._6._1._8.a.f.c._6.e.c.c
        static let BaseURL = "https://api.flickr.com/services/"
        static let PhotosPerRequest = 20 // up to 20 photos per search
        static let HotTagsListCount = 50 // up to 50 trending tags for the week
    }
    
    struct ImageCollection {
        static let BaseImageWidth: Float = 214
        static let ItemsPerRowInVertOrient: CGFloat = 2
        static let ItemsPerRowInHorizOrient: CGFloat = 3
        static let VerticleSpace: CGFloat = 35
        static let HorizontalSpace: CGFloat = 20
    }
    
    struct Other {
        static let ToastDuration: TimeInterval = 4.0
    }
}
