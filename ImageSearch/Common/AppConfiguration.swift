//
//  AppConfiguration.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import UIKit

struct AppConfiguration {
    
    struct ProductionServer {
        static let flickrBaseURL = "https://api.flickr.com/services/rest/"
        static let flickrApiKey = ""._8.c.a._5._5.b.c.a._1._3._8._4.f._4._5.a.b._9._5._7.b._7._6._1._8.a.f.c._6.e.c.c // "8ca55bca1384f45ab957b7618afc6ecc"
        static let photosPerRequest = 20 // up to 20 photos per search
        static let hotTagsCount = 50 // up to 50 trending tags for the week
    }
    
    struct ImageCollection {
        static let baseImageWidth: Float = 214
        static let itemsPerRowInVertOrient: CGFloat = 2
        static let itemsPerRowInHorizOrient: CGFloat = 3
        static let verticleSpace: CGFloat = 35
        static let horizontalSpace: CGFloat = 20
    }
    
    struct MemorySafety {
        static var enabled = true
        static var cacheAfterSearches = 3
    }
    
    struct SQLite {
        static let imageSearchDBPath = try! (FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("image_search.sqlite")).path
    }
    
    struct Other {
        static let toastDuration: TimeInterval = 4.0
        static let allTimesHotTags = ["sunset","beach","water","sky","flowers","nature","white","tree","green","sunrise","portrait","art","light","snow","dog","sun","clouds","cat","flower","park","winter","landscape","street","summer","sea","city","trees","night","yellow","lake","christmas","people","bridge","family","bird","river","pink","house","car","food","blue","old","macro","music","new","moon","home","orange","garden","blackandwhite"]
    }
}
