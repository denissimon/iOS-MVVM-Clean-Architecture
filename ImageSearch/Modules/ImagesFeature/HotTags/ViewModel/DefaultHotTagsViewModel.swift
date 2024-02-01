//
//  DefaultHotTagsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//

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
    var data: Observable<[Tag]> { get }
    var showToast: Observable<String> { get }
    var activityIndicatorVisibility: Observable<Bool> { get }
}

typealias HotTagsViewModel = HotTagsViewModelInput & HotTagsViewModelOutput

class DefaultHotTagsViewModel: HotTagsViewModel {
    
    let tagRepository: TagRepository
    let didSelect: Event<ImageQuery>
    
    var dataForWeekFlickrTags = [Tag]()
    
    var selectedSegment: SegmentType = .week
    
    // Bindings
    let data: Observable<[Tag]> = Observable([])
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
    
    func showErrorToast(_ msg: String = "") {
        if msg.isEmpty {
            self.showToast.value = "Network error"
        } else {
            self.showToast.value = msg
        }
        self.activityIndicatorVisibility.value = false
    }
    
    func getHotTags() {
        self.activityIndicatorVisibility.value = true
                
        hotTagsLoadTask = Task.detached { [weak self] in
            
            let result = await self?.tagRepository.getHotTags()
            
            var allHotFlickrTags = [Tag]()
            
            switch result {
            case .success(let tags):
                if let receivedHotTags = self?.composeFlickrHotTags(type: .week, weekHotTags: tags.hottags.tag) {
                    allHotFlickrTags = receivedHotTags
                }
                self?.dataForWeekFlickrTags = allHotFlickrTags
                self?.activityIndicatorVisibility.value = false
            case .failure(let error):
                if error.error != nil {
                    self?.showErrorToast(error.error!.localizedDescription)
                } else {
                    self?.showErrorToast()
                }
            case .none:
                self?.showErrorToast()
            }
            
            if self?.selectedSegment == .week {
                self?.data.value = allHotFlickrTags
            }
        }
    }
    
    private func composeFlickrHotTags(type: SegmentType, weekHotTags: [Tag]? = nil) -> [Tag] {
        let allTimesHotTagsStr = AppConfiguration.Other.allTimesHotTags
        var allTimesHotTags = [Tag]()
        for tag in allTimesHotTagsStr {
            allTimesHotTags.append(Tag(name: tag))
        }
        
        switch type {
        case .week:
            if weekHotTags != nil {
                return weekHotTags!
            } else {
                return [Tag]()
            }
        case .allTimes:
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
