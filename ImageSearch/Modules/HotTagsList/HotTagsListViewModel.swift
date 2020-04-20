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
                if tags.stat != "ok" {
                    showErrorToast()
                    return
                }
                
                let allHotTags = self.composeHotTags(weekHotTags: tags.hottags.tag)
                self.data = allHotTags
                
                DispatchQueue.main.async {
                    self.activityIndicatorVisibility.value = false
                }
            case .error(let error) :
                if error != nil {
                    showErrorToast(error!.localizedDescription)
                } else {
                    showErrorToast()
                }
            }
        }
    }
    
    private func composeHotTags(weekHotTags: [Tag]) -> [Tag] {
        let allTimesHotTags = [
            Tag(score: "150", name: "sunset"),
            Tag(score: "149", name: "beach"),
            Tag(score: "148", name: "water"),
            Tag(score: "147", name: "sky"),
            Tag(score: "146", name: "flower"),
            Tag(score: "145", name: "nature"),
            Tag(score: "144", name: "blue"),
            Tag(score: "143", name: "night"),
            Tag(score: "142", name: "white"),
            Tag(score: "141", name: "tree"),
            Tag(score: "140", name: "green"),
            Tag(score: "139", name: "flowers"),
            Tag(score: "138", name: "portrait"),
            Tag(score: "137", name: "art"),
            Tag(score: "136", name: "light"),
            Tag(score: "135", name: "snow"),
            Tag(score: "134", name: "dog"),
            Tag(score: "133", name: "sun"),
            Tag(score: "132", name: "clouds"),
            Tag(score: "131", name: "cat"),
            Tag(score: "130", name: "park"),
            Tag(score: "129", name: "winter"),
            Tag(score: "128", name: "landscape"),
            Tag(score: "127", name: "street"),
            Tag(score: "126", name: "summer"),
            Tag(score: "125", name: "sea"),
            Tag(score: "124", name: "city"),
            Tag(score: "123", name: "trees"),
            Tag(score: "122", name: "yellow"),
            Tag(score: "121", name: "lake"),
            Tag(score: "120", name: "christmas"),
            Tag(score: "119", name: "people"),
            Tag(score: "118", name: "bridge"),
            Tag(score: "117", name: "family"),
            Tag(score: "116", name: "bird"),
            Tag(score: "115", name: "river"),
            Tag(score: "114", name: "pink"),
            Tag(score: "113", name: "house"),
            Tag(score: "112", name: "car"),
            Tag(score: "111", name: "food"),
            Tag(score: "110", name: "bw"),
            Tag(score: "109", name: "old"),
            Tag(score: "108", name: "macro"),
            Tag(score: "107", name: "music"),
            Tag(score: "106", name: "new"),
            Tag(score: "105", name: "moon"),
            Tag(score: "104", name: "orange"),
            Tag(score: "103", name: "garden"),
            Tag(score: "102", name: "blackandwhite"),
            Tag(score: "101", name: "home")
        ]
        
        return allTimesHotTags + weekHotTags
    }
    
    func getTagName(for indexPath: IndexPath) -> String {
        return data[indexPath.row].name
    }
}
