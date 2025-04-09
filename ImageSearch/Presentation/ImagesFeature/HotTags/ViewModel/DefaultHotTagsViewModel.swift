import Foundation

enum TagsSegmentType {
    case week
    case allTimes
}

/* Use case scenarios:
 * getHotTagsUseCase.execute()
 */

protocol HotTagsViewModelInput {    
    func triggerDidSelect(with imageQuery: ImageQuery)
    func getHotTags()
    func getDataSource() -> TagsDataSource
    func onSelectedSegmentChange(_ index: Int)
}

protocol HotTagsViewModelOutput {
    var data: Observable<[TagListItemVM]> { get }
    var makeToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var screenTitle: String { get }
}

typealias HotTagsViewModel = HotTagsViewModelInput & HotTagsViewModelOutput

class DefaultHotTagsViewModel: HotTagsViewModel {
    
    private let getHotTagsUseCase: GetHotTagsUseCase
    
    private let didSelect: Event<ImageQuery>
    
    private var dataForWeekTags = [Tag]()
    private var selectedSegment: TagsSegmentType = .week
    
    let screenTitle = NSLocalizedString("Hot Tags", comment: "")
    
    // Bindings
    let data: Observable<[TagListItemVM]> = Observable([])
    let makeToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    
    private var hotTagsLoadTask: Task<Void, Never>?
    
    init(getHotTagsUseCase: GetHotTagsUseCase, didSelect: Event<ImageQuery>) {
        self.getHotTagsUseCase = getHotTagsUseCase
        self.didSelect = didSelect
    }
    
    deinit {
        hotTagsLoadTask?.cancel()
    }
    
    func triggerDidSelect(with imageQuery: ImageQuery) {
        didSelect.notify(imageQuery)
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
                
        hotTagsLoadTask = Task.detached { [weak self] in
            
            let result = await self?.getHotTagsUseCase.execute()
            
            var allHotTags = [Tag]()
            
            switch result {
            case .success(let tags):
                let receivedHotTags = self?.composeHotTags(type: .week, weekHotTags: tags.tags as? [Tag])
                allHotTags = receivedHotTags ?? []
                self?.dataForWeekTags = allHotTags
                self?.activityIndicatorVisibility.value = false
            case .failure(let error):
                let msg = ((error.errorDescription ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                self?.showError(msg)
            case .none:
                return
            }
            
            if self?.selectedSegment == .week {
                self?.data.value = allHotTags
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
