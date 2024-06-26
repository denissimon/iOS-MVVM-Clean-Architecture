import UIKit

class ImageWrapper: Codable {
    
    let image: UIImage?
    
    init(image: UIImage?) {
        self.image = image
    }
    
    enum CodingKeys: String, CodingKey {
        case image
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        if let image = UIImage(data: data) {
            self.image = image
        } else {
            self.image = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let imageData: Data = image?.jpegData(compressionQuality: 1.0) {
            try container.encode(imageData, forKey: .image)
        }
    }
}
