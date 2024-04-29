import Foundation

protocol TagsType {
    var tags: [TagType] { get }
}

struct Tags: Decodable, TagsType {
    
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

extension Tags {
    var tags: [TagType] {
        hottags.tag
    }
}
