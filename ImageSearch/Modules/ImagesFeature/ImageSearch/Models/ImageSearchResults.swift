import Foundation

class ImageSearchResults {
    let id: String
    let searchQuery: ImageQuery
    var searchResults: [ImageListItemVM]
    
    init(id: String, searchQuery: ImageQuery, searchResults: [ImageListItemVM]) {
        self.id = id
        self.searchQuery = searchQuery
        self.searchResults = searchResults
    }
}
