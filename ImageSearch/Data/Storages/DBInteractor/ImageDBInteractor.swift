import Foundation

// Result<Type, AppError> can be used as another way to return the result in saveImage, getImages and checkImagesAreCached methods
protocol ImageDBInteractor {
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type) async -> Bool?
    func getImages<T: Codable>(searchId: String, type: T.Type) async -> [T]?
    func checkImagesAreCached(searchId: String) async -> Bool?
    func deleteAllImages() async
}
