//
//  Extensions.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
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
