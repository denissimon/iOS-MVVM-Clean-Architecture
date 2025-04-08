import Foundation

protocol ImageSearchResultsListItemVM {
    var id: String { get }
    var searchQuery: ImageQuery { get }
    var searchResults_: [ImageListItemVM] { get set }
}

class ImageSearchResults: ImageSearchResultsListItemVM {
    let id: String
    let searchQuery: ImageQuery
    var searchResults: [Image]
    
    init(id: String, searchQuery: ImageQuery, searchResults: [Image]) {
        self.id = id
        self.searchQuery = searchQuery
        self.searchResults = searchResults
    }
}

extension ImageSearchResults {
    var searchResults_: [ImageListItemVM] {
        get { searchResults }
        set { searchResults = newValue as! [Image] }
    }
}
