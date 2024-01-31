//
//  TagRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol TagRepository {
    typealias TagsResult = Result<Tags, NetworkError>
    
    func getHotTags() async -> TagsResult
}
