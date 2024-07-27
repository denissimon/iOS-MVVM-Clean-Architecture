import Foundation

typealias ImageSearchResultsListItemVM = ImageSearchResults

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
