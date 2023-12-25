//
//  Tag.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/12/2020.
//

import Foundation

struct Tag: Decodable {
    
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case name = "_content"
    }
}
