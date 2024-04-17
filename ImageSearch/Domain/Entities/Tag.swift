import Foundation

struct Tag: Decodable {
    
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "_content"
    }
}
