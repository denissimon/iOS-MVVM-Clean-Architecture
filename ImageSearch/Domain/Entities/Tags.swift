import Foundation

struct Tags: Decodable {
    
    struct HotTags: Decodable {
        let tag: [Tag]
    }
    
    let hottags: HotTags
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case hottags
        case stat
    }
}
