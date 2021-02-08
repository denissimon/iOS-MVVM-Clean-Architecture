//
//  HotTagsListViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//

import Foundation
import SwiftEvents

enum HotTagsType {
    case week
    case allTimes
    case all
}

class HotTagsListViewModel {
    
    var networkService: NetworkService
    
    var dataForWeekTags = [Tag]()
    
    private(set) var data = [Tag]() {
        didSet {
            DispatchQueue.main.async {
                self.updateData.trigger(self.data)
            }
        }
    }
    
    // Delegates
    let updateData = Event<[Tag]>()
    let showToast = Event<String>()
    
    // Bindings
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getDataSource() -> TagsDataSource {
        return TagsDataSource(with: data)
    }
    
    func showErrorToast(_ msg: String = "") {
        DispatchQueue.main.async {
            if msg.isEmpty {
                self.showToast.trigger("Network error")
            } else {
                self.showToast.trigger(msg)
            }
            self.activityIndicatorVisibility.value = false
        }
    }
    
    func getFlickrHotTags(of count: Int) {
        
        self.activityIndicatorVisibility.value = true
        
        let endpoint = FlickrAPI.getHotTagsList(count: count)
        
        networkService.requestEndpoint(endpoint, type: Tags.self) { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .done(let tags):
                var allHotTags = [Tag]()
                if tags.stat != "ok" {
                    allHotTags = self.composeHotTags(type: .week, weekHotTags: nil)
                } else {
                    allHotTags = self.composeHotTags(type: .week, weekHotTags: tags.hottags.tag)
                }
                self.dataForWeekTags = allHotTags
                self.data = allHotTags
            case .error(let error):
                if error != nil {
                    self.showErrorToast(error.0!.localizedDescription)
                } else {
                    self.showErrorToast()
                }
                let allHotTags = self.composeHotTags(type: .week, weekHotTags: nil)
                self.data = allHotTags
            }
            
            DispatchQueue.main.async {
                self.activityIndicatorVisibility.value = false
            }
        }
    }
    
    private func composeHotTags(type: HotTagsType, weekHotTags: [Tag]?) -> [Tag] {
        let allTimesHotTagsStr = ["sunset","beach","water","sky","flower","nature","blue","night","white","tree","green","flowers","portrait","art","light","snow","dog","sun","clouds","cat","park","winter","landscape","street","summer","sea","city","trees","yellow","lake","christmas","people","bridge","family","bird","river","pink","house","car","food","bw","old","macro","music","new","moon","orange","garden","blackandwhite","home"]
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
        default:
            if weekHotTags != nil {
                return allTimesHotTags + weekHotTags!
            } else {
                return allTimesHotTags
            }
        }
    }
    
    func getTagName(for indexPath: IndexPath) -> String {
        return data[indexPath.row].name
    }
    
    func onTagsTypeChange(_ index: Int) {
        if index == 0 {
            data = dataForWeekTags
        } else if index == 1 {
            data = composeHotTags(type: .allTimes, weekHotTags: nil)
        }
    }
}
