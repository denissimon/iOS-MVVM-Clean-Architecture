//
//  FlickrAPI.swift
//  ImageSearch
//
//  Created by Denis Simon on 03/09/2020.
//

import Foundation

struct FlickrAPI {
    
    static let baseURL = AppConfiguration.ProductionServer.flickrBaseURL
    
    static let defaultParams = HTTPParams(httpBody: nil, cachePolicy: nil, timeoutInterval: 7.0, headerValues:[
        (value: ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue),
        (value: ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)])
    
    static func search(string: String) -> EndpointType {
        let path = "/rest/?method=flickr.photos.search&api_key=\(AppConfiguration.ProductionServer.flickrApiKey)&text=\(string)&per_page=\(AppConfiguration.ProductionServer.photosPerRequest)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
    
    static func getHotTagsList() -> EndpointType {
        let path = "/rest/?method=flickr.tags.getHotList&api_key=\(AppConfiguration.ProductionServer.flickrApiKey)&period=week&count=\(AppConfiguration.ProductionServer.hotTagsListCount)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
}
