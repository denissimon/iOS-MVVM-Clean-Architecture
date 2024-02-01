//
//  SharedKernel.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/28/2024.
//

import Foundation

/* Note: Behavior classes should ideally contain pure functions without side effects.
Input: an entity / collection of entities, and, optionally, additional parameters
Output: a transformed entity / collection of entities, or a specified simple type like URL? or Int
*/

// Delegate the behavior of Image entity
class ImageBehavior {
    
    static func getImageURL(_ image: Image, size: ImageSize) -> URL? {
        if let url = URL(string: "https://farm\(image.farm).staticflickr.com/\(image.server)/\(image.imageID)_\(image.secret)_\(size.rawValue).jpg") {
            return url
        }
        return nil
    }
    
    // Note: another option is to first make a deep copy of 'image', then it'll be updated and returned
    @discardableResult
    static func updateImage(_ image: Image, newWrapper: ImageWrapper?, for size: ImageSize) -> Image {
        switch size {
        case .thumbnail:
            image.thumbnail = newWrapper
        case .big:
            image.bigImage = newWrapper
        }
        return image
    }
}
