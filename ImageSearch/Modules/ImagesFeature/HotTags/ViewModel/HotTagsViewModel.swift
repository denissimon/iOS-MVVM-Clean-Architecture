//
//  HotTagsViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//

import Foundation

enum SegmentType {
    case week
    case allTimes
}

class HotTagsViewModel {
    
    let tagRepository: TagRepository
    let didSelect: Event<ImageQuery>
    
    var dataForWeekFlickrTags = [Tag]()
    
    var selectedSegment: SegmentType = .week
    
    // Bindings
    let data: Observable<[Tag]> = Observable([])
    let showToast: Observable<String> = Observable("")
    let activityIndicatorVisibility: Observable<Bool> = Observable(false)
    
    private var hotTagsLoadTask: Cancellable?
    
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
    
    func getFlickrHotTags() {
        self.activityIndicatorVisibility.value = true
        
        hotTagsLoadTask = tagRepository.getHotTags() { [weak self] (result) in
            guard let self = self else { return }
            
            var allHotFlickrTags = [Tag]()
            
            switch result {
            case .success(let tags):
                if tags.stat == "ok" {
                    allHotFlickrTags = self.composeFlickrHotTags(type: .week, weekHotTags: tags.hottags.tag)
                }
                self.dataForWeekFlickrTags = allHotFlickrTags
                self.activityIndicatorVisibility.value = false
            case .failure(let error):
                if error.error != nil {
                    self.showErrorToast(error.error!.localizedDescription)
                } else {
                    self.showErrorToast()
                }
            }
            
            if self.selectedSegment == .week {
                self.data.value = allHotFlickrTags
            }
        }
    }
    
    private func composeFlickrHotTags(type: SegmentType, weekHotTags: [Tag]? = nil) -> [Tag] {
        let allTimesHotTagsStr = ["sunset","beach","water","sky","flower","nature","blue","night","white","tree","green","flowers","portrait","art","light","snow","dog","sun","clouds","cat","park","winter","landscape","street","summer","sea","city","trees","yellow","lake","christmas","people","bridge","family","bird","river","pink","house","car","food","sunrise","old","macro","music","new","moon","home","orange","garden","blackandwhite"]
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
                    getFlickrHotTags()
                }
            }
        } else if index == 1 {
            selectedSegment = .allTimes
            data.value = composeFlickrHotTags(type: .allTimes)
        }
    }
}
