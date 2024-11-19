import Foundation

struct FlickrAPI {
    
    static let baseURL = AppConfiguration.ProductionServer.flickrBaseURL
    
    static let defaultParams = HTTPParams(timeoutInterval: 10.0, headerValues:[
        (value: ContentType.applicationJson.rawValue, forHTTPHeaderField: HTTPHeader.accept.rawValue),
        (value: ContentType.applicationFormUrlencoded.rawValue, forHTTPHeaderField: HTTPHeader.contentType.rawValue)])
    
    static func search(_ imageQuery: ImageQuery) -> EndpointType {
        let path = "?method=flickr.photos.search&api_key=\(AppConfiguration.ProductionServer.flickrApiKey)&text=\(imageQuery.query.encodeURIComponent() ?? "")&per_page=\(AppConfiguration.ProductionServer.photosPerRequest)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
    
    static func getHotTags() -> EndpointType {
        let path = "?method=flickr.tags.getHotList&api_key=\(AppConfiguration.ProductionServer.flickrApiKey)&period=week&count=\(AppConfiguration.ProductionServer.hotTagsCount)&format=json&nojsoncallback=1"
        
        let params = FlickrAPI.defaultParams
        
        return Endpoint(
            method: .GET,
            baseURL: FlickrAPI.baseURL,
            path: path,
            params: params)
    }
}
