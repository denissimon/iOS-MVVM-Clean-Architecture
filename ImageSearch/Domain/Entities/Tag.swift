import Foundation

protocol TagType {
    var name: String { get }
}

typealias TagListItemVM = Tag

struct Tag: Decodable, TagType {
    
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "_content"
    }
}
