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
            
            var params = defaultParams
            params.httpBody = post.encode()
            
            return Endpoint(
                method: .POST,
                baseURL: baseURL,
                path: path,
                params: params)
        }
        
        static func updatePost(_ post: Post) -> EndpointType {
            let path = "/posts/\(post.id!)"
            
            var params = defaultParams
            params.httpBody = post.encode()
            
            return Endpoint(
                method: .PUT,
                baseURL: baseURL,
                path: path,
                params: params)
        }
        
        static func patchPost(id: Int, title: String) -> EndpointType {
            let path = "/posts/\(id)"
            
            var params = defaultParams
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
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 10)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let data = try await networkService.request(request).data
            XCTAssertEqual(data.count, 217)
            promise.fulfill()
        } catch {
            XCTFail()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 10)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let (post, response) = try await networkService.request(request, type: Post.self)
            dump(post)
            XCTAssertEqual(post.id, 10)
            XCTAssertEqual(post.title, "optio molestias id quia eum")
            XCTAssertEqual(post.body, "quo et expedita modi cum officia vel magni\ndoloribus qui repudiandae\nvero nisi sit\nquos veniam quod sed accusamus veritatis error")
            XCTAssertEqual(post.userId, 1)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 200)
            promise.fulfill()
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_andErrorReturned_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
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
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andDisabledRequestAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let (data, response) = try await networkService.request(request, configuration: RequestConfiguration(validation: false))
            XCTAssertEqual(data, "{}".data(using: .utf8))
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andDisabledGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        do {
            let endpoint = JSONPlaceholderAPI.getPost(id: 102)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let (data, response) = try await networkService.request(request)
            XCTAssertEqual(data, "{}".data(using: .utf8))
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andChangingGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(urlSession: URLSession(configuration: .default))
        XCTAssertEqual(networkService.autoValidation, true)
            
        networkService.autoValidation = false
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        do {
            let (data, response) = try await networkService.request(request)
            XCTAssertEqual(data, "{}".data(using: .utf8))
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.createPost:
    
    func testRequestPost_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let postToCreate = Post(id: nil, title: "title", body: "body", userId: 2)
            let endpoint = JSONPlaceholderAPI.createPost(postToCreate)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let (post, response) = try await networkService.request(request, type: Post.self)
            dump(post)
            XCTAssertEqual(post.id, 101)
            XCTAssertEqual(post.title, "title")
            XCTAssertEqual(post.body, "body")
            XCTAssertEqual(post.userId, 2)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 201)
            promise.fulfill()
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestPost_withDecodedResult_andUploadTask_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let postToCreate = Post(id: nil, title: "title", body: "body", userId: 2)
            let endpoint = JSONPlaceholderAPI.createPost(postToCreate)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let post = try await networkService.request(request, type: Post.self, configuration: RequestConfiguration(uploadTask: true)).decoded
            dump(post)
            XCTAssertEqual(post.id, 101)
            XCTAssertEqual(post.title, "title")
            XCTAssertEqual(post.body, "body")
            XCTAssertEqual(post.userId, 2)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    
    // JSONPlaceholderAPI.updatePost:
    
    func testRequestPut_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let postToUpdate = Post(id: 1, title: "foo", body: "bar", userId: 1)
            let endpoint = JSONPlaceholderAPI.updatePost(postToUpdate)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let (post, response) = try await networkService.request(request, type: Post.self)
            dump(post)
            XCTAssertEqual(post.id, 1)
            XCTAssertEqual(post.title, "foo")
            XCTAssertEqual(post.body, "bar")
            XCTAssertEqual(post.userId, 1)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 200)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testRequestPut_withDecodedResult_andUploadTask_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let postToUpdate = Post(id: 1, title: "foo", body: "bar", userId: 1)
            let endpoint = JSONPlaceholderAPI.updatePost(postToUpdate)
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let post = try await networkService.request(request, type: Post.self, configuration: RequestConfiguration(uploadTask: true)).decoded
            dump(post)
            XCTAssertEqual(post.id, 1)
            XCTAssertEqual(post.title, "foo")
            XCTAssertEqual(post.body, "bar")
            XCTAssertEqual(post.userId, 1)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.patchPost:
    
    func testRequestPatch_withDecodedResult_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let endpoint = JSONPlaceholderAPI.patchPost(id: 1, title: "foo")
            
            guard let request = RequestFactory.request(endpoint) else {
                XCTFail()
                return
            }
            
            let post = try await networkService.request(request, type: Post.self).decoded
            dump(post)
            XCTAssertEqual(post.id, 1)
            XCTAssertEqual(post.title, "foo")
            XCTAssertEqual(post.body, "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
            XCTAssertEqual(post.userId, 1)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    // Fetch or download a file from the provided URL:
    
    func testFetchFile_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        
        if let (data, response) = try? await networkService.fetchFile(url) {
            XCTAssertNotNil(data)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 200)
            promise.fulfill()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
            let _ = try await networkService.fetchFile(url)
            XCTFail() // shouldn't happen
        } catch {
            let networkError = error as! NetworkError
            XCTAssertEqual(networkError.statusCode, 404)
            promise.fulfill()
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledRequestAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
            let (data, response) = try await networkService.fetchFile(url, configuration: RequestConfiguration(validation: false))
            XCTAssertEqual(data, "{}".data(using: .utf8))
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledGlobalAutoValidation_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
            let (data, response) = try await networkService.fetchFile(url)
            XCTAssertEqual(data, "{}".data(using: .utf8))
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 404)
            promise.fulfill()
        } catch {
            XCTFail() // shouldn't happen
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testDownloadFile_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let (result, response) = try await networkService.downloadFile(url, to: destinationUrl)
            
            XCTAssertEqual(result, true)
            guard let httpResponse = response as? HTTPURLResponse else { return }
            XCTAssertEqual(httpResponse.statusCode, 200)
            
            if FileManager().fileExists(atPath: destinationUrl.path) {
                promise.fulfill()
            }
        } catch {
            if error is NetworkError {
                let networkError = error as! NetworkError
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        await fulfillment(of: [promise], timeout: 5)
    }
    
    func testDownloadFile_whenInvalidURL_asyncAwaitAPI() async throws {
        let promise = expectation(description: #function)
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        
        do {
            let _ = try await networkService.downloadFile(url, to: destinationUrl)
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
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 10)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request) { result in
            if let data = try? result.get().data {
                XCTAssertEqual(data.count, 217)
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 10)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { result in
            switch result {
            case .success(let (post, response)):
                dump(post)
                XCTAssertEqual(post.id, 10)
                XCTAssertEqual(post.title, "optio molestias id quia eum")
                XCTAssertEqual(post.body, "quo et expedita modi cum officia vel magni\ndoloribus qui repudiandae\nvero nisi sit\nquos veniam quod sed accusamus veritatis error")
                XCTAssertEqual(post.userId, 1)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 200)
                promise.fulfill()
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withDecodedResult_andErrorReturned_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { result in
            switch result {
            case .success(_):
                break
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andDisabledRequestAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, configuration: RequestConfiguration(validation: false)) { result in
            switch result {
            case .success(let (data, response)):
                XCTAssertEqual(data, "{}".data(using: .utf8))
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andDisabledGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request) { result in
            switch result {
            case .success(let (data, response)):
                XCTAssertEqual(data, "{}".data(using: .utf8))
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestGet_withErrorReturned_andChangingGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(urlSession: URLSession(configuration: .default))
        XCTAssertEqual(networkService.autoValidation, true)
        
        networkService.autoValidation = false
        
        let endpoint = JSONPlaceholderAPI.getPost(id: 102)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, configuration: RequestConfiguration(validation: false)) { result in
            switch result {
            case .success(let (data, response)):
                XCTAssertEqual(data, "{}".data(using: .utf8))
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.createPost:
    
    func testRequestPost_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { result in
            switch result {
            case .success(let (post, response)):
                dump(post)
                XCTAssertEqual(post.id, 101)
                XCTAssertEqual(post.title, "title")
                XCTAssertEqual(post.body, "body")
                XCTAssertEqual(post.userId, 2)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 201)
                promise.fulfill()
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPost_withDecodedResult_andUploadTask_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: nil, title: "title", body: "body", userId: 2)
        let endpoint = JSONPlaceholderAPI.createPost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self, configuration: RequestConfiguration(uploadTask: true)) { result in
            switch result {
            case .success(let (post, _)):
                dump(post)
                XCTAssertEqual(post.id, 101)
                XCTAssertEqual(post.title, "title")
                XCTAssertEqual(post.body, "body")
                XCTAssertEqual(post.userId, 2)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.updatePost:
    
    func testRequestPut_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let endpoint = JSONPlaceholderAPI.updatePost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { result in
            switch result {
            case .success(let (post, response)):
                dump(post)
                XCTAssertEqual(post.id, 1)
                XCTAssertEqual(post.title, "foo")
                XCTAssertEqual(post.body, "bar")
                XCTAssertEqual(post.userId, 1)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 200)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testRequestPut_withDecodedResult_andUploadTask_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let post = Post(id: 1, title: "foo", body: "bar", userId: 1)
        let endpoint = JSONPlaceholderAPI.updatePost(post)
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self, configuration: RequestConfiguration(uploadTask: true)) { result in
            switch result {
            case .success(let (post, _)):
                dump(post)
                XCTAssertEqual(post.id, 1)
                XCTAssertEqual(post.title, "foo")
                XCTAssertEqual(post.body, "bar")
                XCTAssertEqual(post.userId, 1)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // JSONPlaceholderAPI.patchPost:
    
    func testRequestPatch_withDecodedResult_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
        let endpoint = JSONPlaceholderAPI.patchPost(id: 1, title: "foo")
        
        guard let request = RequestFactory.request(endpoint) else {
            XCTFail()
            return
        }
        
        let _ = networkService.request(request, type: Post.self) { result in
            switch result {
            case .success(let (post, _)):
                dump(post)
                XCTAssertEqual(post.id, 1)
                XCTAssertEqual(post.title, "foo")
                XCTAssertEqual(post.body, "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto")
                XCTAssertEqual(post.userId, 1)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    // Fetch or download the file from the provided URL:
    
    func testFetchFile_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        
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
        
        let networkService = NetworkServiceTests.networkService
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        
        let _ = networkService.fetchFile(url) { result in
            switch result {
            case .success(_):
                break
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
                
                XCTAssertEqual(errorDescription, nil)
                XCTAssertEqual(errorStatusCode, 404)
                XCTAssertEqual(errorDataStr, "{}")
                promise.fulfill()
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledRequestAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkServiceTests.networkService
        XCTAssertEqual(networkService.autoValidation, true)
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        
        let _ = networkService.fetchFile(url, configuration: RequestConfiguration(validation: false)) { response in
            switch response {
            case .success(let (data, response)):
                XCTAssertEqual(data, "{}".data(using: .utf8))
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testFetchFile_whenInvalidURL_andDisabledGlobalAutoValidation_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let networkService = NetworkService(autoValidation: false)
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        
        let _ = networkService.fetchFile(url) { response in
            switch response {
            case .success(let (data, response)):
                XCTAssertEqual(data, "{}".data(using: .utf8))
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 404)
                promise.fulfill()
            case .failure(_):
                break
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFile_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let url = URL(string: "https://farm66.staticflickr.com/65535/53629782624_8da817eff2_b.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        
        let _ = networkService.downloadFile(url, to: destinationUrl) { result in
            switch result {
            case .success(let (result, response)):
                XCTAssertEqual(result, true)
                guard let httpResponse = response as? HTTPURLResponse else { return }
                XCTAssertEqual(httpResponse.statusCode, 200)
                
                if FileManager().fileExists(atPath: destinationUrl.path) {
                    promise.fulfill()
                } else {
                    XCTFail() // shouldn't happen
                }
            case .failure(let networkError):
                let errorDescription = networkError.error?.localizedDescription
                let errorStatusCode = networkError.statusCode
                let errorDataStr = String(data: networkError.data ?? Data(), encoding: .utf8)!
                print("\(#function): \(String(describing: errorDescription)), \(String(describing: errorStatusCode)), \(errorDataStr)")
            }
        }
        
        wait(for: [promise], timeout: 5)
    }
    
    func testDownloadFile_whenInvalidURL_callbacksAPI() {
        let promise = expectation(description: #function)
        
        let url = URL(string: "https://jsonplaceholder.typicode.com/some_image.jpg")!
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        let networkService = NetworkServiceTests.networkService
        
        let _ = networkService.downloadFile(url, to: destinationUrl) { result in
            switch result {
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
