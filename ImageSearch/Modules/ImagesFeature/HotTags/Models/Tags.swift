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
    
    let period: String
    let count: Int
    let hottags: HotTags
    let stat: String
}
