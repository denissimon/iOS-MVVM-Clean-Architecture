//
//  ResponseDecodable.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/04/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

struct ResponseDecodable {
    
    fileprivate var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    public func decode<T: Codable>(_ type: T.Type) -> T? {
        let jsonDecoder = JSONDecoder()
        do {
            let response = try jsonDecoder.decode(T.self, from: data)
            return response
        } catch _ {
            return nil
        }
    }
}
