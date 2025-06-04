import Foundation

// Result<Type, CustomError> can be used as another way to return the result

protocol ImageDBInteractor: Sendable {
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type) -> Bool?
    func getImages<T: Codable>(searchId: String, type: T.Type) -> [T]?
    func checkImagesAreCached(searchId: String) -> Bool?
    func deleteAllImages()
}
