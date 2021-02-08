//
//  Constants.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation
import UAObfuscatedString

struct Constants {
    
    struct Storyboards {
        static let imageSearchVCIdentifier = "ImageSearchViewController"
        static let imageDetailsVCIdentifier = "ImageDetailsViewController"
        static let hotTagsListVCIdentifier = "HotTagsListViewController"
    }
    
    struct FlickrAPI {
        // "8ca55bca1384f45ab957b7618afc6ecc"
        static let apiKey = ""._8.c.a._5._5.b.c.a._1._3._8._4.f._4._5.a.b._9._5._7.b._7._6._1._8.a.f.c._6.e.c.c
        static let baseURL = "https://api.flickr.com/services/"
        static let photosPerRequest = 20 // up to 20 photos per search
        static let hotTagsListCount = 50 // up to 50 trending tags for the week
    }
    
    struct ImageCollection {
        static let baseImageWidth: Float = 214
        static let itemsPerRowInVertOrient: CGFloat = 2
        static let itemsPerRowInHorizOrient: CGFloat = 3
        static let verticleSpace: CGFloat = 35
        static let horizontalSpace: CGFloat = 20
    }
    
    struct Other {
        static let toastDuration: TimeInterval = 4.0
    }
}
