//
//  TagRepositoryTests.swift
//  ImageSearchTests
//
//  Created by Denis Simon on 03/19/2024.
//

import XCTest
@testable import ImageSearch

class TagRepositoryTests: XCTestCase {
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2")]),
        stat: "ok")
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<Tags, NetworkError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<Tags, NetworkError>) {
            self.result = result
        }
        
        func getHotTags() async -> TagsResult {
            apiMethodsCallsCount += 1
            return result
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsSuccess() async {
        let tagRepository = TagRepositoryMock(result: .success(TagRepositoryTests.tagsStub))
        
        let tagsResult = await tagRepository.getHotTags()
        
        let hotTags = try? tagsResult.get().hottags.tag
        
        XCTAssertNotNil(hotTags)
        XCTAssertEqual(hotTags!.count, 2)
        XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
    }
    
    func testGetHotTagsUseCase_whenResultIsFailure() async {
        let tagRepository = TagRepositoryMock(result: .failure(NetworkError(error: nil, statusCode: nil, data: nil)))
        
        let tagsResult = await tagRepository.getHotTags()
        
        let hotTags = try? tagsResult.get().hottags.tag
        
        XCTAssertNil(hotTags)
        XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
    }
}
