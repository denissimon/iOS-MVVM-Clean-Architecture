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
    
    private func getHotTags(completionHandler: @escaping (TagsResult) -> Void) -> Cancellable? {
        let endpoint = FlickrAPI.getHotTags()
        let task = RepositoryTask()
        task.networkTask = apiInteractor.requestEndpoint(endpoint, type: Tags.self) { result in
            guard !task.isCancelled else { return }
            completionHandler(result)
        }
        return task
    }
    
    // MARK: - async methods
    
    func getHotTags() async -> TagsResult {
        await withCheckedContinuation { continuation in
            getHotTags() { result in
                continuation.resume(returning: result)
            }
        }
    }
}
