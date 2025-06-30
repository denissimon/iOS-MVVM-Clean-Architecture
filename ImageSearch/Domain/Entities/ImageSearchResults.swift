import Foundation

protocol ImageSearchResultsVM: Sendable {
    var id: String { get }
    var searchQuery: ImageQuery { get }
    var _searchResults: [ImageVM] { get set }
}

struct ImageSearchResults: Identifiable, ImageSearchResultsVM {
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
    var _searchResults: [ImageVM] {
        get { searchResults }
        set { searchResults = newValue as! [Image] }
    }
}
