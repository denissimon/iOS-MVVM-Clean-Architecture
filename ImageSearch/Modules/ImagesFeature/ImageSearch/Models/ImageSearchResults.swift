//
//  ImageSearchResults.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

class ImageSearchResults {
    let id: String
    let searchQuery: ImageQuery
    var searchResults: [Image]
    
    init(id: String, searchQuery: ImageQuery, searchResults: [Image]) {
        self.id = id
        self.searchQuery = searchQuery
        self.searchResults = searchResults
    }
}
