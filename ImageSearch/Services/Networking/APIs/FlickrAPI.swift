//
//  FlickrAPI.swift
//  ImageSearch
//
//  Created by Denis Simon on 03/09/2020.
//

import Foundation

enum FlickrAPI {
    case search(string: String)
    case getHotTagsList
}

extension FlickrAPI: EndpointType {
    
    var method: Method {
        switch self {
        case .search, .getHotTagsList:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .search(let string):
            return "/rest/?method=flickr.photos.search&api_key=\(Constants.ProductionServer.apiKey)&text=\(string)&per_page=\(Constants.ProductionServer.photosPerRequest)&format=json&nojsoncallback=1"
        case .getHotTagsList:
            return "/rest/?method=flickr.tags.getHotList&api_key=\(Constants.ProductionServer.apiKey)&period=week&count=\(Constants.ProductionServer.hotTagsListCount)&format=json&nojsoncallback=1"
        }
    }
    
    var baseURL: String {
        return Constants.ProductionServer.baseURL
    }
    
    var constructedURL: URL? {
        switch self {
        case .search(_), .getHotTagsList:
            return URL(string: self.baseURL + self.path)
        }
    }
}

