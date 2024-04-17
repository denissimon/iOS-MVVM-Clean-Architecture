import Foundation

// Result<Type, Error> can be used as another way to return the result in saveImage, getImages and checkImagesAreCached
protocol ImageDBInteractor {
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type, completion: @escaping (Bool?) -> Void)
    func getImages<T: Codable>(searchId: String, type: T.Type, completion: @escaping ([T]?) -> Void)
    func checkImagesAreCached(searchId: String, completion: @escaping (Bool?) -> Void)
    func deleteAllImages()
}
