//
//  HotTagsListViewModel.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation
import SwiftEvents

class HotTagsListViewModel {
    
    var networkService: NetworkService
    
    private(set) var data = [Tag]() {
        didSet {
            DispatchQueue.main.async {
                self.updateData.trigger(nil)
            }
        }
    }
    
    // Event-based delegation
    let updateData = Event<Bool?>()
    let showToast = Event<String>()
    
    // Event-based observable properties
    let activityIndicatorVisibility = Observable<Bool>(false)
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func getDataSource() -> TagsDataSource {
        return TagsDataSource(with: data)
    }
    
    func getData() -> [Tag] {
        return data
    }
    
    func getFlickrHotTags(of count: Int) {
        
        self.activityIndicatorVisibility.value = true
        
        let endpoint = FlickrAPI.getHotTagsList(count: count)
        
        networkService.requestEndpoint(endpoint, type: Tags.self) { [weak self] (result) in
            guard let self = self else { return }
            
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
            
            switch result {
            case .done(let tags):
                /*if tags.stat != "ok" {
                    showErrorToast()
                    return
                }*/
                let allHotTags = self.composeHotTags(weekHotTags: tags.hottags.tag)
                self.data = allHotTags
            case .error(let error):
                /*if error != nil {
                    showErrorToast(error!.localizedDescription)
                } else {
                    showErrorToast()
                }*/
                let allHotTags = self.composeHotTags(weekHotTags: [Tag]())
                self.data = allHotTags
            }
            
            DispatchQueue.main.async {
                self.activityIndicatorVisibility.value = false
            }
        }
    }
    
    private func composeHotTags(weekHotTags: [Tag]) -> [Tag] {
        let allTimesHotTagsStr = ["sunset","beach","water","sky","flower","nature","blue","night","white","tree","green","flowers","portrait","art","light","snow","dog","sun","clouds","cat","park","winter","landscape","street","summer","sea","city","trees","yellow","lake","christmas","people","bridge","family","bird","river","pink","house","car","food","bw","old","macro","music","new","moon","orange","garden","blackandwhite","home"]
        var allTimesHotTags = [Tag]()
        for tag in allTimesHotTagsStr {
            allTimesHotTags.append(Tag(name: tag))
        }
        
        return allTimesHotTags + weekHotTags
    }
    
    func getTagName(for indexPath: IndexPath) -> String {
        return data[indexPath.row].name
    }
}
