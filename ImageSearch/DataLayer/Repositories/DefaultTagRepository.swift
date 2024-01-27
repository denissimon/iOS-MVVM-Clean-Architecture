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
            completionHandler(result)
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
