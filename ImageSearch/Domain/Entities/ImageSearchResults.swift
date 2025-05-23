import Foundation

protocol ImageSearchResultsListItemVM: AnyObject {
    var id: String { get }
    var searchQuery: ImageQuery { get }
    var _searchResults: [ImageListItemVM] { get set }
}

class ImageSearchResults: Identifiable, ImageSearchResultsListItemVM {
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
    var _searchResults: [ImageListItemVM] {
        get { searchResults }
        set { searchResults = newValue as! [Image] }
    }
}
