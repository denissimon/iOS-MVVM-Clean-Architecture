//
//  Helpers.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit

class Helpers {
    
    static func getImage(data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}
