import Foundation

protocol TagType {
    var id: UUID { get }
    var name: String { get }
}

typealias TagVM = TagType

struct Tag: Decodable, Identifiable, TagType {
    let id = UUID()
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "_content"
    }
}
