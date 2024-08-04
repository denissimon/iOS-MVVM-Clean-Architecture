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
    
    // MARK: - async/await API
    
    // JSONPlaceholderAPI.getPost:
    
    func testRequestGet_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestGet")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 10)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let resultData = try await networkService.request(request)
            XCTAssertEqual(resultData.count, 217)
            promise.fulfill()
        } catch {
            XCTFail()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestGet_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 10)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self)
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 10)
            XCTAssertEqual(returnedPost.title, "optio molestias id quia eum")
            XCTAssertEqual(returnedPost.body, "quo et expedita modi cum officia vel magni\ndoloribus qui repudiandae\nvero nisi sit\nquos veniam quod sed accusamus veritatis error")
            XCTAssertEqual(returnedPost.userId, 1)
            promise.fulfill()
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_andErrorReturned_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestGet_withDecodedResult_andErrorReturned")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let _ = try await networkService.request(request, type: Post.self)
            XCTFail() // shouldn't happen
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestWithStatusCodeGet")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 1)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let response = try await networkService.requestWithStatusCode(request)
            XCTAssertEqual(response.result.count, 292)
            XCTAssertEqual(response.statusCode, 200)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let _ = try await networkService.requestWithStatusCode(request)
            XCTFail() // shouldn't happen
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestWithStatusCodeGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_andDisabledRequestAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned_andDisabledRequestAutoValidation")
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let response = try await networkService.requestWithStatusCode(request, config: RequestConfig(autoValidation: false))
            XCTAssertEqual(response.result, "{}".data(using: .utf8))
            XCTAssertEqual(response.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_andDisabledGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned_andDisabledGlobalAutoValidation")
        
        let networkService = NetworkService(autoValidation: false)
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let response = try await networkService.requestWithStatusCode(request)
            XCTAssertEqual(response.result, "{}".data(using: .utf8))
            XCTAssertEqual(response.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.createPost:
    
    func testRequestPost_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestPost_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let post = Post(id: nil, title: "title", body: "body", userId: 2)
            let endpoint = JSONPlaceholderAPI.createPost(post)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self)
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 101)
            XCTAssertEqual(returnedPost.title, "title")
            XCTAssertEqual(returnedPost.body, "body")
            XCTAssertEqual(returnedPost.userId, 2)
            promise.fulfill()
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestPost: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestPost_withDecodedResult_andUploadTask_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestPost_withDecodedResult_andUploadTask")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let post = Post(id: nil, title: "title", body: "body", userId: 2)
            let endpoint = JSONPlaceholderAPI.createPost(post)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self, config: RequestConfig(uploadTask: true))
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 101)
            XCTAssertEqual(returnedPost.title, "title")
            XCTAssertEqual(returnedPost.body, "body")
            XCTAssertEqual(returnedPost.userId, 2)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodePost_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestWithStatusCodePost")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        if let response = try? await networkService.requestWithStatusCode(request) {
            XCTAssertEqual(response.result.count, 68)
            XCTAssertEqual(response.statusCode, 201)
            promise.fulfill()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.updatePost:
    
    func testRequestPut_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestPut_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
            let endpoint = JSONPlaceholderAPI.updatePost(post)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self)
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 1)
            XCTAssertEqual(returnedPost.title, "foo")
            XCTAssertEqual(returnedPost.body, "bar")
            XCTAssertEqual(returnedPost.userId, 1)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestPut_withDecodedResult_andUploadTask_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestPut_withDecodedResult_andUploadTask")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
            let endpoint = JSONPlaceholderAPI.updatePost(post)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self, config: RequestConfig(uploadTask: true))
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 1)
            XCTAssertEqual(returnedPost.title, "foo")
            XCTAssertEqual(returnedPost.body, "bar")
            XCTAssertEqual(returnedPost.userId, 1)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.patchPost:
    
    func testRequestPatch_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testRequestPatch_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let endpoint = JSONPlaceholderAPI.patchPost(id: 1, title: "foo")
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let returnedPost = try await networkService.request(request, type: Post.self)
            dump(returnedPost)
            XCTAssertEqual(returnedPost.id, 1)
            XCTAssertEqual(returnedPost.title, "foo")
            XCTAssertEqual(returnedPost.body, "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            XCTAssertEqual(returnedPost.userId, 1)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // Fetch or download the file from the provided URL:
    
    func testFetchFile_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testFetchFile")
        
        let networkService = NetworkServiceTests.networkService
        let data = try? await networkService.fetchFile(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!)
        XCTAssertNotNil(data)
        promise.fulfill()
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testFetchFileWithStatusCode")
        
        let networkService = NetworkServiceTests.networkService
        if let data = try? await networkService.fetchFileWithStatusCode(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) {
            XCTAssertNotNil(data.result)
            XCTAssertEqual(data.statusCode, 200)
            promise.fulfill()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL")
        
        let networkService = NetworkServiceTests.networkService
        do {
            let _ = try await networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!)
            XCTFail() // shouldn't happen
        } catch {
            let networkError = error as! NetworkError
            XCTAssertEqual(networkError.statusCode, 404)
            promise.fulfill()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_andDisabledRequestAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL_andDisabledRequestAutoValidation")
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        do {
            let response = try await networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!, config: RequestConfig(autoValidation: false))
            XCTAssertEqual(response.result, "{}".data(using: .utf8))
            XCTAssertEqual(response.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_andDisabledGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL_andDisabledGlobalAutoValidation")
        
        let networkService = NetworkService(autoValidation: false)
        do {
            let response = try await networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!)
            XCTAssertEqual(response.result, "{}".data(using: .utf8))
            XCTAssertEqual(response.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testDownloadFile_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testDownloadFile")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        do {
            guard try await networkService.downloadFile(url: url, to: destinationUrl) else {
                XCTFail() // shouldn't happen
                return
            }
            if FileManager().fileExists(atPath: destinationUrl.path) {
                XCTAssertTrue(true)
                promise.fulfill()
            }
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFile: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testDownloadFileWithStatusCode")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        do {
            let response = try await networkService.downloadFileWithStatusCode(url: url, to: destinationUrl)
            
            XCTAssertEqual(response.result, true)
            XCTAssertEqual(response.statusCode, 200)
            
            guard try await networkService.downloadFile(url: url, to: destinationUrl) else {
                XCTFail() // shouldn't happen
                return
            }
            if FileManager().fileExists(atPath: destinationUrl.path) {
                XCTAssertTrue(true)
                promise.fulfill()
            }
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFileWithStatusCode: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode_whenInvalidURL_asyncAwaitAPI() async throws {
        let promise = expectation(description: "testDownloadFileWithStatusCode_whenInvalidURL")
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        do {
            let _ = try await networkService.downloadFileWithStatusCode(url: url, to: destinationUrl)
            XCTFail() // shouldn't happen
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                XCTAssertEqual(networkError.statusCode, 404)
                promise.fulfill()
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // MARK: - callbacks API
    
    // JSONPlaceholderAPI.getPost:
    
    func testRequestGet_callbacksAPI() {
        let promise = expectation(description: "testRequestGet")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 10)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request) { response in
            if let resultData = try? response.get() {
                XCTAssertEqual(resultData.count, 217)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: "testRequestGet_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 10)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 10)
                XCTAssertEqual(returnedPost.title, "optio molestias id quia eum")
                XCTAssertEqual(returnedPost.body, "quo et expedita modi cum officia vel magni\ndoloribus qui repudiandae\nvero nisi sit\nquos veniam quod sed accusamus veritatis error")
                XCTAssertEqual(returnedPost.userId, 1)
                promise.fulfill()
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_andErrorReturned_callbacksAPI() {
        let promise = expectation(description: "testRequestGet_withDecodedResult_andErrorReturned")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { response in
            switch response {
            case .success(_):
                break
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_callbacksAPI() {
        let promise = expectation(description: "testRequestWithStatusCodeGet")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 1)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.requestWithStatusCode(request) { response in
            if let resultData = try? response.get() {
                XCTAssertEqual(resultData.result!.count, 292)
                XCTAssertEqual(resultData.statusCode, 200)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_callbacksAPI() {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.requestWithStatusCode(request) { response in
            switch response {
            case .success(_):
                break
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestWithStatusCodeGet: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_andDisabledRequestAutoValidation_callbacksAPI() {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned_andDisabledRequestAutoValidation")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(networkService.autoValidation, true)
        let _ = networkService.requestWithStatusCode(request, config: RequestConfig(autoValidation: false)) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result.result, "{}".data(using: .utf8))
                XCTAssertEqual(result.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodeGet_withErrorReturned_andDisabledGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: "testRequestWithStatusCodeGet_withErrorReturned_andDisabledGlobalAutoValidation")
        
        let networkService = NetworkService(autoValidation: false)
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.requestWithStatusCode(request) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result.result, "{}".data(using: .utf8))
                XCTAssertEqual(result.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.createPost:
    
    func testRequestPost_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: "testRequestPost_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 101)
                XCTAssertEqual(returnedPost.title, "title")
                XCTAssertEqual(returnedPost.body, "body")
                XCTAssertEqual(returnedPost.userId, 2)
                promise.fulfill()
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testRequestPost: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPost_withDecodedResult_andUploadTask_callbacksAPI() {
        let promise = expectation(description: "testRequestPost_withDecodedResult_andUploadTask")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self, config: RequestConfig(uploadTask: true)) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 101)
                XCTAssertEqual(returnedPost.title, "title")
                XCTAssertEqual(returnedPost.body, "body")
                XCTAssertEqual(returnedPost.userId, 2)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestWithStatusCodePost_callbacksAPI() {
        let promise = expectation(description: "testRequestWithStatusCodePost")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.requestWithStatusCode(request) { response in
            if let resultData = try? response.get() {
                XCTAssertEqual(resultData.result!.count, 68)
                XCTAssertEqual(resultData.statusCode, 201)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.updatePost:
    
    func testRequestPut_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: "testRequestPut_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let endpoint = JSONPlaceholderAPI.updatePost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "bar")
                XCTAssertEqual(returnedPost.userId, 1)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPut_withDecodedResult_andUploadTask_callbacksAPI() {
        let promise = expectation(description: "testRequestPut_withDecodedResult_andUploadTask")
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let endpoint = JSONPlaceholderAPI.updatePost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self, config: RequestConfig(uploadTask: true)) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "bar")
                XCTAssertEqual(returnedPost.userId, 1)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.patchPost:
    
    func testRequestPatch_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: "testRequestPatch_withDecodedResult")
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.patchPost(id: 1, title: "foo")
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { response in
            switch response {
            case .success(let returnedPost):
                dump(returnedPost)
                XCTAssertEqual(returnedPost.id, 1)
                XCTAssertEqual(returnedPost.title, "foo")
                XCTAssertEqual(returnedPost.body, "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
                XCTAssertEqual(returnedPost.userId, 1)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // Fetch or download the file from the provided URL:
    
    func testFetchFile_callbacksAPI() {
        let promise = expectation(description: "testFetchFile")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFile(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) { response in
            switch response {
            case .success(let data):
                XCTAssertNotNil(data)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_callbacksAPI() {
        let promise = expectation(description: "testFetchFileWithStatusCode")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!) { response in
            switch response {
            case .success(let data):
                XCTAssertNotNil(data.result)
                XCTAssertEqual(data.statusCode, 200)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_callbacksAPI() {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL")
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!) { response in
            switch response {
            case .success(_):
                break
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testFetchFileWithStatusCode: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_andDisabledRequestAutoValidation_callbacksAPI() {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL_andDisabledRequestAutoValidation")
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!, config: RequestConfig(autoValidation: false)) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result.result, "{}".data(using: .utf8))
                XCTAssertEqual(result.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFileWithStatusCode_whenInvalidURL_andDisabledGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: "testFetchFileWithStatusCode_whenInvalidURL_andDisabledGlobalAutoValidation")
        
        let networkService = NetworkService(autoValidation: false)
        let _ = networkService.fetchFileWithStatusCode(url: URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result.result, "{}".data(using: .utf8))
                XCTAssertEqual(result.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFile_callbacksAPI() {
        let promise = expectation(description: "testDownloadFile")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFile(url: url, to: destinationUrl) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result, true)
                
                if FileManager().fileExists(atPath: destinationUrl.path) {
                    XCTAssertTrue(true)
                    promise.fulfill()
                } else {
                    XCTFail() // shouldn't happen
                }
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFile: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode_callbacksAPI() {
        let promise = expectation(description: "testDownloadFileWithStatusCode")
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFileWithStatusCode(url: url, to: destinationUrl) { response in
            switch response {
            case .success(let result):
                XCTAssertEqual(result.result, true)
                XCTAssertEqual(result.statusCode, 200)
                
                if FileManager().fileExists(atPath: destinationUrl.path) {
                    XCTAssertTrue(true)
                    promise.fulfill()
                } else {
                    XCTFail() // shouldn't happen
                }
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("testDownloadFileWithStatusCode: \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFileWithStatusCode_whenInvalidURL_callbacksAPI() {
        let promise = expectation(description: "testDownloadFileWithStatusCode_whenInvalidURL")
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        let _ = networkService.downloadFileWithStatusCode(url: url, to: destinationUrl) { response in
            switch response {
            case .success(_):
                break
            case .failure(let networkError):
                XCTAssertEqual(networkError.statusCode, 404)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
}
