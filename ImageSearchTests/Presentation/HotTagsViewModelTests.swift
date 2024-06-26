import XCTest
@testable import ImageSearch

class HotTagsViewModelTests: XCTestCase {
    
    var observablesTriggerCount = 0
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2"), Tag(name: "tag3")]),
        stat: "ok")
    
    static let syncQueue = DispatchQueue(label: "HotTagsViewModelTests")
    
    class TagRepositoryMock: TagRepository {
        
        let result: Result<TagsType, AppError>
        var apiMethodsCallsCount = 0
        
        init(result: Result<TagsType, AppError>) {
            self.result = result
        }
        
        func getHotTags() async -> TagsResult {
            HotTagsViewModelTests.syncQueue.sync {
                apiMethodsCallsCount += 1
            }
            return result
        }
    }
    
    override func tearDown() {
        super.tearDown()
        HotTagsViewModelTests.syncQueue.sync {
            self.observablesTriggerCount = 0
        }
    }
    
    private func bind(_ hotTagsViewModel: HotTagsViewModel) {
        hotTagsViewModel.data.bind(self) { [weak self] _ in
            HotTagsViewModelTests.syncQueue.sync {
                self?.observablesTriggerCount += 1
            }
        }
        hotTagsViewModel.showToast.bind(self) { [weak self] _ in
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
        let hotTagsViewModel: HotTagsViewModel!
        
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let didSelect = Event<ImageQuery>()
        hotTagsViewModel = DefaultHotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        
        XCTAssertEqual(hotTagsViewModel.data.value.count, 3)
        XCTAssertEqual(hotTagsViewModel.showToast.value, "")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 3) // activityIndicatorVisibility, activityIndicatorVisibility, data
        }
    }
    
    func testGetHotTags_whenResultIsFailure() async throws {
        let hotTagsViewModel: HotTagsViewModel!
        
        let tagRepository = TagRepositoryMock(result: .failure(AppError.default()))
        let didSelect = Event<ImageQuery>()
        hotTagsViewModel = DefaultHotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        XCTAssertNotEqual(hotTagsViewModel.showToast.value, "")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 4) // activityIndicatorVisibility, showToast, activityIndicatorVisibility, data
        }
    }
    
    func testOnSelectedSegmentChange_whenAllTimesSelected() {
        let hotTagsViewModel: HotTagsViewModel!
        
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let didSelect = Event<ImageQuery>()
        hotTagsViewModel = DefaultHotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.onSelectedSegmentChange(1)
        
        XCTAssertFalse(hotTagsViewModel.data.value.isEmpty)
        XCTAssertEqual(hotTagsViewModel.data.value[5].name, "nature")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 1) // data
        }
    }
    
    func testOnSelectedSegmentChange_whenWeekSelected() async throws {
        let hotTagsViewModel: HotTagsViewModel!
        
        let tagRepository = TagRepositoryMock(result: .success(HotTagsViewModelTests.tagsStub))
        let didSelect = Event<ImageQuery>()
        hotTagsViewModel = DefaultHotTagsViewModel(tagRepository: tagRepository, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.onSelectedSegmentChange(1)
        hotTagsViewModel.onSelectedSegmentChange(0)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        try await Task.sleep(nanoseconds: 1 * 500_000_000)
        
        XCTAssertFalse(hotTagsViewModel.data.value.isEmpty)
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "tag1")
        
        hotTagsViewModel.onSelectedSegmentChange(1)
        hotTagsViewModel.onSelectedSegmentChange(0)
        
        XCTAssertEqual(hotTagsViewModel.data.value[0].name, "tag1")
        HotTagsViewModelTests.syncQueue.sync {
            XCTAssertEqual(self.observablesTriggerCount, 10) // data and activityIndicatorVisibility several times
        }
    }
}
