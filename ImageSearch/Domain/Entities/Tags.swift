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
}

extension Tags {
    var tags: [TagType] {
        hottags.tag
    }
}
