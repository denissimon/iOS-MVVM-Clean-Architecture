//
//  FlickrAPITests.swift
//  ImageSearchTests
//
//  Created by Denis Simon on 03/31/2024.
//

import XCTest
@testable import ImageSearch

class NetworkServiceMock: NetworkServiceType {
       
    let urlSession: URLSession
    
    let responceData: Data
    
    init(urlSession: URLSession = URLSession.shared, responceData: Data) {
        self.urlSession = urlSession
        self.responceData = responceData
    }
    
    func request(_ endpoint: EndpointType, completion: @escaping (Result<Data, NetworkError>) -> Void) -> NetworkCancellable? {
        completion(.success(responceData))
        return nil
    }
    
    func request<T: Decodable>(_ endpoint: EndpointType, type: T.Type, completion: @escaping (Result<T, NetworkError>) -> Void) -> NetworkCancellable? {
        guard let decoded = ResponseDecodable.decode(type, data: responceData) else {
            completion(.failure(NetworkError(error: nil, code: nil)))
            return nil
        }
        completion(.success(decoded))
        return nil
    }
    
    func fetchFile(url: URL, completion: @escaping (Data?) -> Void) -> NetworkCancellable? {
        return nil
    }
    
    func log(_ str: String) {}
}

class FlickrAPITests: XCTestCase {
    
    // https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=8ca55bca1384f45ab957b7618afc6ecc&text=%22nice%22&per_page=5&format=json&nojsoncallback=1
    static let searchResultJsonStub = """
    {"photos":{"page":1,"pages":22461,"perpage":5,"total":112301,"photo":[{"id":"53624890009","owner":"105731165@N07","secret":"5cd918efcd","server":"65535","farm":66,"title":"Andrea  Modelo  Model","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982545","owner":"200344658@N04","secret":"27599b24dd","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624540146","owner":"200344658@N04","secret":"861e943634","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982400","owner":"200344658@N04","secret":"f16ea5ebe5","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624740978","owner":"200344658@N04","secret":"90689d079d","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0}]},"stat":"ok"}
    """
    
    // https://api.flickr.com/services/rest/?method=flickr.tags.getHotList&api_key=8ca55bca1384f45ab957b7618afc6ecc&period=week&count=2&format=json&nojsoncallback=1
    static let getHotTagsResultJsonStub = """
    {"period":"day","count":2,"hottags":{"tag":[{"_content":"digital","thm_data":{"photos":{"photo":[{"id":"30239309451","secret":"10f9bdfddd","server":"8273","farm":9,"owner":"135037635@N03","username":null,"title":"Fire on the sky","ispublic":1,"isfriend":0,"isfamily":0}]}}},{"_content":"shine","thm_data":{"photos":{"photo":[{"id":"26695870685","secret":"0e25f93ea0","server":"1641","farm":2,"owner":"76458369@N07","username":null,"title":"#Storm","ispublic":1,"isfriend":0,"isfamily":0}]}}}]},"stat":"ok"}
    """
    
    func testGetHotTags() async {
        let endpoint = FlickrAPI.getHotTags()
        let networkServiceMock = NetworkServiceMock(responceData: FlickrAPITests.getHotTagsResultJsonStub.data(using: .utf8)!)
        let _ = networkServiceMock.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(let tags):
                if tags.stat != "ok" {
                    XCTFail()
                }
                XCTAssertEqual(tags.hottags.tag.count, 2)
                XCTAssertEqual(tags.hottags.tag[0].name, "digital")
                XCTAssertEqual(tags.hottags.tag[1].name, "shine")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testSearch() async {
        let endpoint = FlickrAPI.search(ImageQuery(query: "random"))
        let expectedData = FlickrAPITests.searchResultJsonStub.data(using: .utf8)!
        let networkServiceMock = NetworkServiceMock(responceData: expectedData)
        
        var resultData = Data()
        let _ = networkServiceMock.request(endpoint) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, expectedData)
                resultData = data
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let diContainer = DIContainer()
        let imageRepository = diContainer.makeImageRepository()
        
        let images = await imageRepository.prepareImages(resultData)
        
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 5)
        XCTAssertEqual(images![0].title, "Andrea  Modelo  Model")
    }
    
    func testNetworkError() async {
        let promise = expectation(description: "testNetworkError")
        
        var endpoint = FlickrAPI.getHotTags()
        endpoint.path = "?method=flickr.photos.search&api_key=12345&text=nice&per_page=20&format=json&nojsoncallback=1" // Invalid API Key
        let networkService = NetworkService()
        let _ = networkService.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("The operation couldn’t be completed"))
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 1)
    }
}
