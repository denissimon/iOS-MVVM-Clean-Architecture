import Foundation

class DefaultTagRepository: TagRepository {
    
    let apiInteractor: APIInteractor
    
    init(apiInteractor: APIInteractor) {
        self.apiInteractor = apiInteractor
    }
    
    private func getHotTags(completionHandler: @escaping (TagsResult) -> Void) -> NetworkCancellable? {
        let endpoint = FlickrAPI.getHotTags()
        return apiInteractor.request(endpoint, type: Tags.self) { result in
            switch result {
            case .success(let tags):
                if tags.stat != "ok" {
                    completionHandler(.failure(NetworkError()))
                    return
                }
                completionHandler(.success(tags))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    // MARK: - async methods
    
    func getHotTags() async -> TagsResult {
        await withCheckedContinuation { continuation in
            let _ = getHotTags() { result in
                continuation.resume(returning: result)
            }
        }
    }
}
