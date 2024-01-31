//
//  DefaultTagRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

class DefaultTagRepository: TagRepository {
    
    let apiInteractor: APIInteractor
    
    init(apiInteractor: APIInteractor) {
        self.apiInteractor = apiInteractor
    }
    
    private func getHotTags(completionHandler: @escaping (TagsResult) -> Void) -> NetworkCancellable? {
        let endpoint = FlickrAPI.getHotTags()
        let networkTask = apiInteractor.requestEndpoint(endpoint, type: Tags.self) { result in
            switch result {
            case .success(let tags):
                if tags.stat != "ok" {
                    completionHandler(.failure(NetworkError(error: nil, code: nil)))
                    return
                }
                completionHandler(.success(tags))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
        return networkTask
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
