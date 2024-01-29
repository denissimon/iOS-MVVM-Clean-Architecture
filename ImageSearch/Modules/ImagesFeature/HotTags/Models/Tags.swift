//
//  Tags.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/12/2020.
//

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
