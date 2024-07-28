import Foundation

protocol ImageRepository {
    func searchImages(_ imageQuery: ImageQuery) async -> Result<Data?, CustomError>
    func prepareImages(_ imagesData: Data?) async -> [Image]?
    func getImage(url: URL) async -> Data?
    
    func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool?
    func getImages(searchId: String) async -> [ImageType]?
    func checkImagesAreCached(searchId: String) async -> Bool?
    func deleteAllImages() async
}
