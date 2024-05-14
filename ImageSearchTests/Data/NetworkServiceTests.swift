import XCTest
@testable import ImageSearch

class NetworkServiceTests: XCTestCase {

    static let networkService = NetworkService(urlSession: URLSession(configuration: .default))
    
    struct Post: Codable {
        var id: Int?
        var title: String
        var body: String
        var userId: Int
    }
    
    struct JSONPlaceholderAPI {
        
        static let baseURL = "https://jsonplaceholder.typicode.com"
        
        static let defaultParams = HTTPParams(headerValues:[
            (value: ContentType.applicationJson.rawValue+"; charset=UTF-8", forHTTPHeaderField: HTTPHeader.contentType.rawValue)
        ])
        
        static func getPost(id: Int) -> EndpointType {
            let path = "/posts/\(id)"
            return Endpoint(
                method: .GET,
                baseURL: baseURL,
                path: path,
                params: nil)
        }
        
        static func createPost(_ post: Post) -> EndpointType {
            let path = "/posts"
            
            let params = defaultParams
            params.httpBody = post.encode()
            
            return Endpoint(
                method: .POST,
                baseURL: baseURL,
                path: path,
                params: params)
        }
        
        static func updatePost(_ post: Post) -> EndpointType {
            let path = "/posts/\(post.id!)"
            
            let params = defaultParams
            params.httpBody = post.encode()
            
            return Endpoint(
                method: .PUT,
                baseURL: baseURL,
                path: path,
                params: params)
        }
        
        static func patchPost(id: Int, title: String) -> EndpointType {
            let path = "/posts/\(id)"
            
            let params = defaultParams
            params.httpBody = "{\"title\": \"\(title)\"}".data(using: .utf8)
            
            return Endpoint(
                method: .PATCH,
                baseURL: baseURL,
                path: path,
                params: params)
        }
        
        static func deletePost(id: Int) -> EndpointType {
            let path = "/posts/\(id)"
            return Endpoint(
                method: .DELETE,
                baseURL: baseURL,
                path: path,
                params: nil)
        }
    }
    
    // JSONPlaceholderAPI.getPost:
    
    func testRequestGet() {
        let promise = expectation(description: "testRequestGet")
        
        let networkService = NetworkServiceTests.networkService
        let networkTask = networkService.request(JSONPlaceholderAPI.getPost(id: 10)) { result in
            if let resultData = try? result.get() {
                XCTAssertEqual(resultData.count, 217)
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult() {
        let promise = expectation(description: "testRequestGet")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.request(JSONPlaceholderAPI.getPost(id: 10), type: Post.self) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 10)
                XCTAssertEqual(returnedPost.title, "optio molestias id quia eum")
                XCTAssertEqual(returnedPost.body, "quo et expedita modi cum officia vel magni\ndoloribus qui repudiandae\nvero nisi sit\nquos veniam quod sed accusamus veritatis error")
                XCTAssertEqual(returnedPost.userId, 1)
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_andErrorReturned() {
        let promise = expectation(description: "testRequestGet")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.request(JSONPlaceholderAPI.getPost(id: 102), type: Post.self) { result in
            switch result {
            case .success(_):
                XCTFail() // shouldn't happen
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet() {
        let promise = expectation(description: "testRequestWithStatusCodeGet")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.requestWithStatusCode(JSONPlaceholderAPI.getPost(id: 1)) { result in
            if let resultData = try? result.get() {
                XCTAssertEqual(resultData.result!.count, 292)
                XCTAssertEqual(resultData.statusCode, 200)
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned() {
        let promise = expectation(description: "testRequestWithStatusCodeGet")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.requestWithStatusCode(JSONPlaceholderAPI.getPost(id: 102)) { result in
            if let resultData = try? result.get() {
                XCTAssertEqual(String(data: resultData.result!, encoding: .utf8), "{}")
                XCTAssertEqual(resultData.statusCode, 404)
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.createPost:
    
    func testRequestPost_withDecodedResult() {
        let promise = expectation(description: "testRequestPost")
        
        let networkService = NetworkServiceTests.networkService
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let _ = networkService.request(JSONPlaceholderAPI.createPost(post), type: Post.self) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 101)
                XCTAssertEqual(returnedPost.title, "title")
                XCTAssertEqual(returnedPost.body, "body")
                XCTAssertEqual(returnedPost.userId, 2)
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestPost: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPost_withDecodedResult_andUploadTask() {
        let promise = expectation(description: "testRequestPost")
        
        let networkService = NetworkServiceTests.networkService
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let _ = networkService.request(JSONPlaceholderAPI.createPost(post), type: Post.self, uploadTask: true) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 101)
                XCTAssertEqual(returnedPost.title, "title")
                XCTAssertEqual(returnedPost.body, "body")
                XCTAssertEqual(returnedPost.userId, 2)
            case .failure(_):
                XCTFail() // shouldn't happen
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodePost() {
        let promise = expectation(description: "testRequestWithStatusCodePost")
        
        let networkService = NetworkServiceTests.networkService
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let _ = networkService.requestWithStatusCode(JSONPlaceholderAPI.createPost(post)) { result in
            if let resultData = try? result.get() {
                XCTAssertEqual(resultData.result!.count, 68)
                XCTAssertEqual(resultData.statusCode, 201)
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.updatePost:
    
    func testRequestPut_withDecodedResult() {
        let promise = expectation(description: "testRequestPut")
        
        let networkService = NetworkServiceTests.networkService
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let _ = networkService.request(JSONPlaceholderAPI.updatePost(post), type: Post.self) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "bar")
                XCTAssertEqual(returnedPost.userId, 1)
            case .failure(_):
                XCTFail() // shouldn't happen
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPut_withDecodedResult_andUploadTask() {
        let promise = expectation(description: "testRequestPut")
        
        let networkService = NetworkServiceTests.networkService
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let _ = networkService.request(JSONPlaceholderAPI.updatePost(post), type: Post.self, uploadTask: true) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "bar")
                XCTAssertEqual(returnedPost.userId, 1)
            case .failure(_):
                XCTFail() // shouldn't happen
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.patchPost:
    
    func testRequestPatch_withDecodedResult() {
        let promise = expectation(description: "testRequestPatch")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.request(JSONPlaceholderAPI.patchPost(id: 1, title: "foo"), type: Post.self) { result in
            switch result {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
                XCTAssertEqual(returnedPost.userId, 1)
            case .failure(_):
                XCTFail() // shouldn't happen
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // Fetch or download the file from the provided URL:
    
    func testFetchFile() {
        let promise = expectation(description: "testFetchFile")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) { data in
            XCTAssertNotNil(data)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode() {
        let promise = expectation(description: "testFetchFileWithStatusCode")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) { data in
            XCTAssertNotNil(data.result)
            XCTAssertEqual(data.statusCode, 200)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL() {
        let promise = expectation(description: "testFetchFileWithStatusCode")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!) { data in
            XCTAssertNil(data.result)
            XCTAssertEqual(data.statusCode, 404)
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFile() {
        let promise = expectation(description: "testDownloadFile")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFile(url: url, to: destinationUrl) { result in
            switch result {
            case .success(let result):
                XCTAssertEqual(result, true)
                
                if FileManager().fileExists(atPath: destinationUrl.path) {
                    XCTAssertTrue(true)
                } else {
                    XCTFail() // shouldn't happen
                }
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFile: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode() {
        let promise = expectation(description: "testDownloadFileWithStatusCode")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFileWithStatusCode(url: url, to: destinationUrl) { result in
            switch result {
            case .success(let result):
                XCTAssertEqual(result.result, true)
                XCTAssertEqual(result.statusCode, 200)
                
                if FileManager().fileExists(atPath: destinationUrl.path) {
                    XCTAssertTrue(true)
                } else {
                    XCTFail() // shouldn't happen
                }
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFileWithStatusCode: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode_whenInvalidURL() {
        let promise = expectation(description: "testDownloadFileWithStatusCode")
        
        let url = URL(string: "https://farm1.staticflickr.com/server/id1_secret1_m.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFileWithStatusCode(url: url, to: destinationUrl) { result in
            switch result {
            case .success(_):
                break
            case .failure(let networkError):
                XCTAssertEqual(networkError.statusCode, 404)
            }
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 5)
    }
}
