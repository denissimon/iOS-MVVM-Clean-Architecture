import Foundation

enum SegmentType {
    case week
    case allTimes
}

/* Use Case scenarios:
 * tagRepository.getHotTags()
 */

protocol HotTagsViewModelInput {
    var didSelect: Event<ImageQuery> { get }
    func getHotTags()
    func getDataSource() -> TagsDataSource
    func onSelectedSegmentChange(_ index: Int)
}

protocol HotTagsViewModelOutput {
    var data: Observable<[TagListItemVM]> { get }
    var showToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
    var screenTitle: String { get }
}

typealias HotTagsViewModel = HotTagsViewModelInput & HotTagsViewModelOutput

class DefaultHotTagsViewModel: HotTagsViewModel {
    
    private let tagRepository: TagRepository
    
    let didSelect: Event<ImageQuery>
    
    private var dataForWeekFlickrTags = [Tag]()
    private var selectedSegment: SegmentType = .week
    
    let screenTitle = NSLocalizedString("Hot Tags", comment: "")
    
    // Bindings
    let data: Observable<[TagListItemVM]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    
    private var hotTagsLoadTask: Task<Void, Never>?
    
    init(tagRepository: TagRepository, didSelect: Event<ImageQuery>) {
        self.tagRepository = tagRepository
        self.didSelect = didSelect
    }
    
    deinit {
        hotTagsLoadTask?.cancel()
    }
    
    func getDataSource() -> TagsDataSource {
        return TagsDataSource(with: data.value)
    }
    
    private func showErrorToast(_ msg: String = "") {
        showToast.value = !msg.isEmpty ? msg : NSLocalizedString("An error has occurred", comment: "")
        activityIndicatorVisibility.value = false
    }
    
    func getHotTags() {
        getFlickrHotTags()
    }
    
    private func getFlickrHotTags() {
        self.activityIndicatorVisibility.value = true
                
        hotTagsLoadTask = Task.detached { [weak self] in
            
            let result = await self?.tagRepository.getHotTags()
            
            var allHotFlickrTags = [Tag]()
            
            switch result {
            case .success(let tags):
                let receivedHotTags = self?.composeFlickrHotTags(type: .week, weekHotTags: tags.tags as? [Tag])
                allHotFlickrTags = receivedHotTags ?? []
                self?.dataForWeekFlickrTags = allHotFlickrTags
                self?.activityIndicatorVisibility.value = false
            case .failure(let error):
                let msg = ((error.failureReason ?? "") + " " + (error.recoverySuggestion ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                self?.showErrorToast(msg)
            case .none:
                return
            }
            
            if self?.selectedSegment == .week {
                self?.data.value = allHotFlickrTags
            }
        }
    }
    
    private func composeFlickrHotTags(type: SegmentType, weekHotTags: [Tag]? = nil) -> [Tag] {
        switch type {
        case .week:
            if weekHotTags != nil {
                return weekHotTags!
            } else {
                return [Tag]()
            }
        case .allTimes:
            let allTimesHotTagsStr = AppConfiguration.Other.allTimesHotTags
            var allTimesHotTags = [Tag]()
            for tag in allTimesHotTagsStr {
                allTimesHotTags.append(Tag(name: tag))
            }
            return allTimesHotTags
        }
    }
    
    func onSelectedSegmentChange(_ index: Int) {
        if index == 0 {
            selectedSegment = .week
            if !dataForWeekFlickrTags.isEmpty {
                data.value = dataForWeekFlickrTags
            } else {
                data.value = []
                if !activityIndicatorVisibility.value {
                    getHotTags()
                }
            }
        } else if index == 1 {
            selectedSegment = .allTimes
            data.value = composeFlickrHotTags(type: .allTimes)
        }
    }
}
