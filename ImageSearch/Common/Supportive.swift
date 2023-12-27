//
//  Supportive.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

class Supportive {
    
    static func getImage(data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}

struct ImageWrapper: Codable {
    let image: UIImage?
    
    init(image: UIImage) {
        self.image = image
    }
    
    enum CodingKeys: String, CodingKey {
        case image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        if let image = UIImage(data: data) {
            self.image = image
        } else {
            // Error Decode
            self.image = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let imageData: Data = image?.pngData() {
            try container.encode(imageData, forKey: .image)
        } else {
            // Error Encode
        }
    }
}
