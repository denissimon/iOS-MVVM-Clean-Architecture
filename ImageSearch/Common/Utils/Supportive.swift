import UIKit

class Supportive {
    static func toUIImage(from data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }
        return nil
    }
}

class DeepCopier {
    static func copy<T: Codable>(of object: T) -> T? {
       do {
           let json = try JSONEncoder().encode(object)
           return try JSONDecoder().decode(T.self, from: json)
       } catch {
           return nil
       }
    }
}

class ImageWrapper {
    
    let uiImage: UIImage?
    
    init(uiImage: UIImage?) {
        self.uiImage = uiImage
    }
    
    enum CodingKeys: String, CodingKey {
        case uiImage
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.uiImage)
        if let image = UIImage(data: data) {
            uiImage = image
        } else {
            uiImage = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let imageData = uiImage?.jpegData(compressionQuality: 1.0) {
            try container.encode(imageData, forKey: .uiImage)
        }
    }
}
