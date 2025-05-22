import XCTest
@testable import ImageSearch

class HotTagsViewModelTests: XCTestCase {
    
    var observablesTriggerCount = 0
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2"), Tag(name: "tag3")]),
        stat: "ok")
    
    static let syncQueue = DispatchQueue(label: "HotTagsViewModelTests")
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<TagsType, CustomError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<TagsType, CustomError>) {
            self.result = result
        }
        
        func getHotTags() async -> Result<TagsType, CustomError> {
            HotTagsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result
        }
    }
    
    override func tearDown() {
        super.tearDown()
        HotTagsViewModelTests.syncQueue.sync {
            observablesTriggerCount = 0
        }
    }
    
    private func bind(_ hotTagsViewModel: HotTagsViewModel) {
        hotTagsViewModel.data.bind(self) { [weak self] _ in
            HotTagsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        hotTagsViewModel.makeToast.bind(self) { [weak self] _ in
            HotTagsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        hotTagsViewModel.activityIndicatorVisibility.bind(self) { [weak self] _ in
            HotTagsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
    }
    
    func testGetHotTags_whenResultIsSuccess() async throws {
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<ImageQuery>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        await hotTagsViewModel.toTestHotTagsLoadTask?.value
        
        XCTAssertEqual(hotTagsViewModel.data.value.count, 3)
        XCTAssertEqual(hotTagsViewModel.makeToast.value, "")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 3) // activityIndicatorVisibility, activityIndicatorVisibility, data
        }
    }
    
    func testGetHotTags_whenResultIsFailure() async throws {
        let tagRepository = TagRepositoryMock(result: .failure(CustomError.internetConnection()))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<ImageQuery>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        await hotTagsViewModel.toTestHotTagsLoadTask?.value
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        XCTAssertNotEqual(hotTagsViewModel.makeToast.value, "")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 4) // activityIndicatorVisibility, makeToast, activityIndicatorVisibility, data
        }
    }
    
    func testOnSelectedSegmentChange_whenAllTimesSelected() {
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<ImageQuery>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.onSelectedSegmentChange(1)
        
        XCTAssertFalse(hotTagsViewModel.data.value.isEmpty)
        XCTAssertEqual(hotTagsViewModel.data.value[5].name, "nature")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 1) // data
        }
    }
    
    func testOnSelectedSegmentChange_whenWeekSelected() async throws {
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<ImageQuery>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.onSelectedSegmentChange(1) // triggers 'data'
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "sunset")
        
        hotTagsViewModel.onSelectedSegmentChange(0) // triggers 'data' (data.value = []), 'activityIndicatorVisibility', 'activityIndicatorVisibility', 'data'
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        await hotTagsViewModel.toTestHotTagsLoadTask?.value
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "tag1")
        
        hotTagsViewModel.onSelectedSegmentChange(1) // triggers 'data'
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "sunset")
        
        hotTagsViewModel.onSelectedSegmentChange(0) // triggers 'data'
        XCTAssertFalse(hotTagsViewModel.data.value.isEmpty)
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "tag1")
        
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(observablesTriggerCount, 7) // data, data, activityIndicatorVisibility, activityIndicatorVisibility, data, data, data
        }
    }
}
