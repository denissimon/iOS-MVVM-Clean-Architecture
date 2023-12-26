//
//  TagRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol TagRepository {
    typealias TagsResult = Result<Tags, NetworkError>
    
    // Can be used together with or instead of the async method:
    //func getHotTags(completionHandler: @escaping (TagsResult) -> Void) -> Cancellable?
    
    func getHotTags() async -> TagsResult
}
