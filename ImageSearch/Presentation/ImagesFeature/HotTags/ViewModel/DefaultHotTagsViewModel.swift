import Foundation

enum TagsSegmentType: String, CaseIterable {
    case week = "Week"
    case allTimes = "All Times"
}

/* Use case scenarios:
 * getHotTagsUseCase.execute()
 */

protocol HotTagsViewModelInput {
    func getHotTags()
    func triggerDidSelect(tagName: String)
    func onSelectedSegmentChange(_ index: Int)
    func getDataSource() -> TagsDataSource
}

protocol HotTagsViewModelOutput {
    var data: Observable<[TagVM]> { get }
    var makeToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var screenTitle: String { get }
}

typealias HotTagsViewModel = HotTagsViewModelInput & HotTagsViewModelOutput

class DefaultHotTagsViewModel: HotTagsViewModel {
    
    private let getHotTagsUseCase: GetHotTagsUseCase
    
    private let didSelect: Event<String>
    
    private var dataForWeekTags = [Tag]()
    private var selectedSegment: TagsSegmentType = .week
    
    let screenTitle = NSLocalizedString("Hot Tags", comment: "")
    
    // Bindings
    let data: Observable<[TagVM]> = Observable([])
    let makeToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    
    private var hotTagsLoadTask: Task<Void, Never>? {
        willSet { hotTagsLoadTask?.cancel() }
    }
    
    init(getHotTagsUseCase: GetHotTagsUseCase, didSelect: Event<String>) {
        self.getHotTagsUseCase = getHotTagsUseCase
        self.didSelect = didSelect
    }
    
    deinit {
        hotTagsLoadTask?.cancel()
    }
    
    func triggerDidSelect(tagName: String) {
        didSelect.notify(tagName)
    }
    
    func getDataSource() -> TagsDataSource {
        TagsDataSource(with: data.value)
    }
    
    private func showError(_ msg: String = "") {
        makeToast.value = !msg.isEmpty ? msg : NSLocalizedString("An error has occurred", comment: "")
        activityIndicatorVisibility.value = false
    }
    
    func getHotTags() {
        getFlickrHotTags()
    }
    
    private func getFlickrHotTags() {
        activityIndicatorVisibility.value = true
        
        hotTagsLoadTask = Task { [weak self] in            
            let result = await self?.getHotTagsUseCase.execute()
            
            if Task.isCancelled { return }
            
            guard let self, let result else { return }
            
            var allHotTags = [Tag]()
            
            switch result {
            case .success(let tags):
                allHotTags = composeHotTags(type: .week, weekHotTags: tags.tags as? [Tag])
                dataForWeekTags = allHotTags
                activityIndicatorVisibility.value = false
            case .failure(let error):
                let msg = ((error.errorDescription ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                showError(msg)
            }
            
            if selectedSegment == .week {
                data.value = allHotTags
            }
        }
    }
    
    private func composeHotTags(type: TagsSegmentType, weekHotTags: [Tag]? = nil) -> [Tag] {
        switch type {
        case .week:
            return weekHotTags ?? [Tag]()
        case .allTimes:
            var allTimesHotTags = [Tag]()
            for tag in AppConfiguration.Other.allTimesHotTags {
                allTimesHotTags.append(Tag(name: tag))
            }
            return allTimesHotTags
        }
    }
    
    func onSelectedSegmentChange(_ index: Int) {
        if index == 0 {
            selectedSegment = .week
            if !dataForWeekTags.isEmpty {
                data.value = dataForWeekTags
            } else {
                data.value = []
                if !activityIndicatorVisibility.value {
                    getHotTags()
                }
            }
        } else if index == 1 {
            selectedSegment = .allTimes
            data.value = composeHotTags(type: .allTimes)
        }
    }
}

extension DefaultHotTagsViewModel {
    var toTestHotTagsLoadTask: Task<Void, Never>? {
        hotTagsLoadTask
    }
}
