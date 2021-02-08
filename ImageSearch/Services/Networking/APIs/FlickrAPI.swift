//
//  FlickrAPI.swift
//  ImageSearch
//
//  Created by Denis Simon on 03/09/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

enum FlickrAPI {
    case search(string: String)
    case getHotTagsList(count: Int)
}

extension FlickrAPI: EndpointType {
    
    var method: Method {
        switch self {
        case .search, .getHotTagsList:
            return .GET
        }
    }
    
    var baseURL: String {
        return Constants.FlickrAPI.BaseURL
    }
    
    var path: String {
        switch self {
        case .search(let string):
            return "rest/?method=flickr.photos.search&api_key=\(Constants.FlickrAPI.ApiKey)&text=\(string)&per_page=\(Constants.FlickrAPI.PhotosPerRequest)&format=json&nojsoncallback=1"
        case .getHotTagsList(let count):
            return "rest/?method=flickr.tags.getHotList&api_key=\(Constants.FlickrAPI.ApiKey)&period=week&count=\(count)&format=json&nojsoncallback=1"
        }
    }
    
    var constructedURL: URL? {
        switch self {
        case .search(_), .getHotTagsList(_):
            return URL(string: self.baseURL + self.path)
        }
    }
}

