import XCTest
@testable import ImageSearch

class TagUseCasesTests: XCTestCase {
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2")]),
        stat: "ok")
    
    static let syncQueue = DispatchQueue(label: "TagUseCasesTests")
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<TagsType, CustomError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<TagsType, CustomError>) {
            self.result = result
        }
        
        func getHotTags() async -> Result<TagsType, CustomError> {
            TagUseCasesTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsSuccess() async {
        let tagRepository = TagRepositoryMock(result: .success(TagUseCasesTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        
        let tagsResult = await getHotTagsUseCase.execute()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNotNil(hotTags)
        XCTAssertEqual(hotTags!.count, 2)
        TagUseCasesTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
    
    func testGetHotTagsUseCase_whenResultIsFailure() async {
        let tagRepository = TagRepositoryMock(result: .failure(CustomError.internetConnection()))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        
        let tagsResult = await getHotTagsUseCase.execute()
        
        let hotTags = try? tagsResult.get().tags
        
        XCTAssertNil(hotTags)
        TagUseCasesTests.syncQueue.sync {
            XCTAssertEqual(tagRepository.apiMethodsCallsCount, 1)
        }
    }
}
