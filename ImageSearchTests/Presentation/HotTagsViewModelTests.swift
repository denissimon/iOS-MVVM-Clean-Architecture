import XCTest
@testable import ImageSearch

@MainActor
final class HotTagsViewModelTests: XCTestCase, Sendable {
    
    var observablesTriggerCount = 0
    
    static let tagsStub = Tags(
        hottags: Tags.HotTags(tag: [Tag(name: "tag1"), Tag(name: "tag2"), Tag(name: "tag3")]),
        stat: "ok")
    
    final class TagRepositoryMock: TagRepository, @unchecked Sendable {
        
        let response: Result<TagsType, CustomError>
        var apiMethodsCallsCount = 0
        
        init(response: Result<TagsType, CustomError>) {
            self.response = response
        }
        
        func getHotTags() async -> Result<TagsType, CustomError> {
            Task { @MainActor in
                apiMethodsCallsCount += 1
            }
            return response
        }
    }
    
    override func tearDown() {
        super.tearDown()
        Task { @MainActor in
            observablesTriggerCount = 0
        }
    }
    
    private func bind(_ hotTagsViewModel: HotTagsViewModel) {
        hotTagsViewModel.data.bind(self) { [weak self] _ in
            Task { @MainActor in
                self?.observablesTriggerCount += 1
            }
        }
        hotTagsViewModel.makeToast.bind(self) { [weak self] _ in
            Task { @MainActor in
                self?.observablesTriggerCount += 1
            }
        }
        hotTagsViewModel.activityIndicatorVisibility.bind(self) { [weak self] _ in
            Task { @MainActor in
                self?.observablesTriggerCount += 1
            }
        }
    }
    
    func testGetHotTags_whenResultIsSuccess() async throws {
        let tagRepository = TagRepositoryMock(response: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<String>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        await hotTagsViewModel.toTestHotTagsLoadTask?.value
        
        XCTAssertEqual(hotTagsViewModel.data.value.count, 3)
        XCTAssertEqual(hotTagsViewModel.makeToast.value, "")
        Task { @MainActor in
            XCTAssertEqual(observablesTriggerCount, 3) // activityIndicatorVisibility, activityIndicatorVisibility, data
        }
    }
    
    func testGetHotTags_whenResultIsFailure() async throws {
        let tagRepository = TagRepositoryMock(response: .failure(CustomError.internetConnection()))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<String>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.getHotTags()
        await hotTagsViewModel.toTestHotTagsLoadTask?.value
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        XCTAssertNotEqual(hotTagsViewModel.makeToast.value, "")
        Task { @MainActor in
            XCTAssertEqual(observablesTriggerCount, 4) // activityIndicatorVisibility, makeToast, activityIndicatorVisibility, data
        }
    }
    
    func testOnSelectedSegmentChange_whenAllTimesSelected() {
        let tagRepository = TagRepositoryMock(response: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<String>()
        let hotTagsViewModel = DefaultHotTagsViewModel(getHotTagsUseCase: getHotTagsUseCase, didSelect: didSelect)
        bind(hotTagsViewModel)
        
        XCTAssertTrue(hotTagsViewModel.data.value.isEmpty)
        
        hotTagsViewModel.onSelectedSegmentChange(1)
        
        XCTAssertFalse(hotTagsViewModel.data.value.isEmpty)
        XCTAssertEqual(hotTagsViewModel.data.value[5].name, "nature")
        Task { @MainActor in
            XCTAssertEqual(observablesTriggerCount, 1) // data
        }
    }
    
    func testOnSelectedSegmentChange_whenWeekSelected() async throws {
        let tagRepository = TagRepositoryMock(response: .success(HotTagsViewModelTests.tagsStub))
        let getHotTagsUseCase = DefaultGetHotTagsUseCase(tagRepository: tagRepository)
        let didSelect = Event<String>()
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
        
        Task { @MainActor in
            XCTAssertEqual(observablesTriggerCount, 7) // data, data, activityIndicatorVisibility, activityIndicatorVisibility, data, data, data
        }
    }
}
