//
//  Supportive.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

class Supportive {
    
    static func toUIImage(from data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}
