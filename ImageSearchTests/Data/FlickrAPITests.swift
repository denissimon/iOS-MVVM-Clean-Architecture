import XCTest
@testable import ImageSearch

class FlickrAPITests: XCTestCase {
    
    // https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=8ca55bca1384f45ab957b7618afc6ecc&text=%22nice%22&per_page=5&format=json&nojsoncallback=1
    static let searchResultJsonStub = """
    {"photos":{"page":1,"pages":22461,"perpage":5,"total":112301,"photo":[{"id":"53624890009","owner":"105731165@N07","secret":"5cd918efcd","server":"65535","farm":66,"title":"Andrea  Modelo  Model","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982545","owner":"200344658@N04","secret":"27599b24dd","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624540146","owner":"200344658@N04","secret":"861e943634","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624982400","owner":"200344658@N04","secret":"f16ea5ebe5","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0},{"id":"53624740978","owner":"200344658@N04","secret":"90689d079d","server":"65535","farm":66,"title":"FC Nantes - OGC Nice","ispublic":1,"isfriend":0,"isfamily":0}]},"stat":"ok"}
    """
    
    // https://api.flickr.com/services/rest/?method=flickr.tags.getHotList&api_key=8ca55bca1384f45ab957b7618afc6ecc&period=week&count=2&format=json&nojsoncallback=1
    static let getHotTagsResultJsonStub = """
    {"period":"day","count":2,"hottags":{"tag":[{"_content":"digital","thm_data":{"photos":{"photo":[{"id":"30239309451","secret":"10f9bdfddd","server":"8273","farm":9,"owner":"135037635@N03","username":null,"title":"Fire on the sky","ispublic":1,"isfriend":0,"isfamily":0}]}}},{"_content":"shine","thm_data":{"photos":{"photo":[{"id":"26695870685","secret":"0e25f93ea0","server":"1641","farm":2,"owner":"76458369@N07","username":null,"title":"#Storm","ispublic":1,"isfriend":0,"isfamily":0}]}}}]},"stat":"ok"}
    """
    
    class NetworkServiceAsyncAwaitMock: NetworkServiceAsyncAwaitType {
           
        let urlSession: URLSession
        
        let responseData: Data
        
        init(urlSession: URLSession = URLSession.shared, responseData: Data) {
            self.urlSession = urlSession
            self.responseData = responseData
        }
        
        func request(_ request: URLRequest, configuration: RequestConfiguration? = nil) async throws -> (data: Data, response: URLResponse) {
            (responseData, URLResponse())
        }

        func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil) async throws -> (decoded: T, response: URLResponse) {
            guard let decoded = try? JSONDecoder().decode(type, from: responseData) else {
                throw NetworkError()
            }
            return (decoded, URLResponse())
        }
        
        func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil) async throws -> (data: Data?, response: URLResponse) {
            ("image".data(using: .utf8), URLResponse())
        }
        
        func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil) async throws -> (result: Bool, response: URLResponse) {
            (true, URLResponse())
        }
    }
    
    class NetworkServiceCallbacksMock: NetworkServiceCallbacksType {
           
        let urlSession: URLSession
        
        let responseData: Data
        
        init(urlSession: URLSession = URLSession.shared, responseData: Data) {
            self.urlSession = urlSession
            self.responseData = responseData
        }
        
        func request(_ request: URLRequest, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success((responseData, URLResponse())))
            return nil
        }

        func request<T: Decodable>(_ request: URLRequest, type: T.Type, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(decoded: T, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
            guard let decoded = try? JSONDecoder().decode(type, from: responseData) else {
                completion(.failure(NetworkError()))
                return nil
            }
            completion(.success((decoded, URLResponse())))
            return nil
        }
        
        func fetchFile(_ url: URL, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(data: Data?, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success(("image".data(using: .utf8), URLResponse())))
            return nil
        }
        
        func downloadFile(_ url: URL, to localUrl: URL, configuration: RequestConfiguration? = nil, completion: @escaping (Result<(result: Bool, response: URLResponse?), NetworkError>) -> Void) -> NetworkCancellable? {
            completion(.success((true, URLResponse())))
            return nil
        }
    }
    
    // MARK: - async/await API
    
    func testSearch_asyncAwaitAPI() async throws {
        let endpoint = FlickrAPI.search(ImageQuery(query: "random")!)
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let expectedData = FlickrAPITests.searchResultJsonStub.data(using: .utf8)!
        
        let networkServiceMock = NetworkServiceAsyncAwaitMock(responseData: expectedData)
        
        var data: Data? = Data()
        do {
            data = try await networkServiceMock.request(request).data
            XCTAssertEqual(data, expectedData)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let diContainer = DIContainer()
        let imageRepository = DefaultImageRepository(apiInteractor: diContainer.apiInteractor, imageDBInteractor: diContainer.imageDBInteractor)
        
        let images = imageRepository.toTestPrepareImages(data)
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 5)
        XCTAssertEqual(images![0].flickr?.imageID, "53624890009")
    }
    
    func testGetHotTags_asyncAwaitAPI() async throws {
        let endpoint = FlickrAPI.getHotTags()
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkServiceMock = NetworkServiceAsyncAwaitMock(responseData: FlickrAPITests.getHotTagsResultJsonStub.data(using: .utf8)!)
        
        do {
            let tags = try await networkServiceMock.request(request, type: Tags.self).decoded
            if tags.stat != "ok" {
                XCTFail()
            }
            XCTAssertEqual(tags.hottags.tag.count, 2)
            XCTAssertEqual(tags.hottags.tag[0].name, "digital")
            XCTAssertEqual(tags.hottags.tag[1].name, "shine")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testNetworkError_whenInvalidResponse_asyncAwaitAPI() async throws {
        let endpoint = FlickrAPI.getHotTags()
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkServiceMock = NetworkServiceAsyncAwaitMock(responseData: "some_data".data(using: .utf8)!)
        
        do {
            let _ = try await networkServiceMock.request(request, type: Tags.self)
            XCTFail()
        } catch {
            XCTAssertTrue(!error.localizedDescription.isEmpty)
        }
    }
    
    func testNetworkError_whenInvalidAPIKey_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        var endpoint = FlickrAPI.getHotTags()
        endpoint.path = "?method=flickr.photos.search&api_key=12345&text=nice&per_page=20&format=json&nojsoncallback=1"
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkService = NetworkService()
        
        do {
            let _ = try await networkService.request(request, type: Tags.self)
            XCTFail()
        } catch {
            XCTAssertTrue(!error.localizedDescription.isEmpty)
            if error is NetworkError {
                let error = error as! NetworkError
                
                if error.data != nil {
                    let dataStr = String(data: error.data!, encoding: .utf8)
                    XCTAssertEqual(dataStr, "{\"stat\":\"fail\",\"code\":100,\"message\":\"Invalid API Key (Key has invalid format)\"}")
                    promise.fulfill()
                }
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService()
        
        do {
            let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
            let (data, response) = try await networkService.fetchFile(url)
            XCTAssertNotNil(data)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 200)
            promise.fulfill()
        } catch {
            XCTFail()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService()
        
        do {
            let url = URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!
            let _ = try await networkService.fetchFile(url)
            XCTFail()
        } catch {
            XCTAssertTrue(!error.localizedDescription.isEmpty)
            if error is NetworkError {
                let error = error as! NetworkError
                XCTAssertEqual(error.statusCode, 404)
                promise.fulfill()
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        do {
            let url = URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!
            let (data, response) = try await networkService.fetchFile(url)
            XCTAssertEqual(data, nil)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // MARK: - callbacks API
    
    func testSearch_callbacksAPI() async {
        let endpoint = FlickrAPI.search(ImageQuery(query: "random")!)
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let expectedData = FlickrAPITests.searchResultJsonStub.data(using: .utf8)!
        
        let networkServiceMock = NetworkServiceCallbacksMock(responseData: expectedData)
        
        var receivedData: Data? = Data()
        let _ = networkServiceMock.request(request) { result in
            switch result {
            case .success(let (data, _)):
                receivedData = data
                XCTAssertEqual(data, expectedData)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        
        let diContainer = DIContainer()
        let imageRepository = DefaultImageRepository(apiInteractor: diContainer.apiInteractor, imageDBInteractor: diContainer.imageDBInteractor)
        
        let images = imageRepository.toTestPrepareImages(receivedData)
        XCTAssertNotNil(images)
        XCTAssertEqual(images!.count, 5)
        XCTAssertEqual(images![0].flickr?.imageID, "53624890009")
    }
    
    func testGetHotTags_callbacksAPI() {
        let endpoint = FlickrAPI.getHotTags()
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkServiceMock = NetworkServiceCallbacksMock(responseData: FlickrAPITests.getHotTagsResultJsonStub.data(using: .utf8)!)
        
        let _ = networkServiceMock.request(request, type: Tags.self) { result in
            switch result {
            case .success(let (tags, _)):
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
    
    func testNetworkError_whenInvalidResponse_callbacksAPI() {
        let endpoint = FlickrAPI.getHotTags()
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkServiceMock = NetworkServiceCallbacksMock(responseData: "some_data".data(using: .utf8)!)
        
        let _ = networkServiceMock.request(request, type: Tags.self) { result in
            switch result {
            case .success(_):
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(!error.localizedDescription.isEmpty)
            }
        }
    }
    
    func testNetworkError_whenInvalidAPIKey_callbacksAPI() {
        let promise = expectation(description: #function)
        
        var endpoint = FlickrAPI.getHotTags()
        endpoint.path = "?method=flickr.photos.search&api_key=12345&text=nice&per_page=20&format=json&nojsoncallback=1"
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let networkService = NetworkService()
        
        let _ = networkService.request(request, type: Tags.self) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                XCTAssertTrue(!error.localizedDescription.isEmpty)
                if error.data != nil {
                    let dataStr = String(data: error.data!, encoding: .utf8)
                    XCTAssertEqual(dataStr, "{\"stat\":\"fail\",\"code\":100,\"message\":\"Invalid API Key (Key has invalid format)\"}")
                    promise.fulfill()
                }
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService()
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        
        let _ = networkService.fetchFile(url) { result in
            switch result {
            case .success(let (data, response)):
                XCTAssertNotNil(data)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 200)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService()
        
        let url = URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!
        
        let _ = networkService.fetchFile(url) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                XCTAssertTrue(!error.localizedDescription.isEmpty)
                XCTAssertEqual(error.statusCode, 404)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        let url = URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!
        
        let _ = networkService.fetchFile(url) { result in
            switch result {
            case .success(let (data, response)):
                XCTAssertEqual(data, nil)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
}
