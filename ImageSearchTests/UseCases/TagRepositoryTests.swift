import XCTest
@testable import ImageSearch

class TagRepositoryTests: XCTestCase {
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2")]),
        stat: "ok")
    
    static let syncQueue = DispatchQueue(label: "TagRepositoryTests")
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<TagsType, NetworkError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<TagsType, NetworkError>) {
            self.result = result
        }
        
        func getHotTags() async -> TagsResult {
            TagRepositoryTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsSuccess() async {
        let tagRepository = TagRepositoryMock(result: .success(TagRepositoryTests.tagsStub))
        
        let tagsResult = await tagRepository.getHotTags()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNotNil(hotTags)
        XCTAssertEqual(hotTags!.count, 2)
        TagRepositoryTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsFailure() async {
        let tagRepository = TagRepositoryMock(result: .failure(NetworkError()))
        
        let tagsResult = await tagRepository.getHotTags()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNil(hotTags)
        TagRepositoryTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
}
