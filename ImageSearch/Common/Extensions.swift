//
//  Extensions.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

extension String {
    
    func encodeURIComponent() -> String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }
    
    func decodeURIComponent() -> String? {
        return self.removingPercentEncoding
    }
}

extension Array where Element == ImageWrapper {
    func toUIImageArray() -> [UIImage] {
        return self.map { $0.image }
    }
}
