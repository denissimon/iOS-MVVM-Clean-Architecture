//
//  Tag.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/12/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

struct Tag: Codable {
    
    let score: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case score = "score"
        case name = "_content"
    }
}