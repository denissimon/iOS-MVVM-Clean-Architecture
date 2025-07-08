import Foundation

class DefaultImageRepository: ImageRepository {
    
    private let apiInteractor: APIInteractor
    private let imageDBInteractor: ImageDBInteractor
    
    init(apiInteractor: APIInteractor, imageDBInteractor: ImageDBInteractor) {
        self.apiInteractor = apiInteractor
        self.imageDBInteractor = imageDBInteractor
    }
    
    // MARK: - API methods
    
    private func prepareImages(_ imagesData: Data?) -> [Image]? {
        guard
            let imagesData = imagesData, !imagesData.isEmpty,
            let resultsDictionary = try? JSONSerialization.jsonObject(with: imagesData) as? [String: AnyObject],
            let stat = resultsDictionary["stat"] as? String
            else { return nil }

        if stat != "ok" { return nil }
        
        guard
            let container = resultsDictionary["photos"] as? [String: AnyObject],
            let photos = container["photo"] as? [[String: AnyObject]]
            else { return nil }
        
        let imagesArr: [Image] = photos.compactMap { imageDict in
            return Image(flickrParams: imageDict)
        }
        
        guard !imagesArr.isEmpty else { return nil }
        
        return imagesArr
    }
    
    func searchImages(_ imageQuery: ImageQuery) async -> Result<[ImageType], CustomError> {
        let endpoint = FlickrAPI.search(imageQuery)
        do {
            let data = try await apiInteractor.request(endpoint)
            if let images = prepareImages(data) {
                return .success(images)
            } else {
                return .failure(CustomError.app(.apiClient))
            }
        } catch {
            return .failure(error as! CustomError)
        }
    }
    
    func getImage(url: URL) async -> Data? {
        do {
            return try await apiInteractor.fetchFile(url)
        } catch {
            return nil
        }
    }
    
    // MARK: - DB methods
    
    func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
        await withCheckedContinuation { continuation in
            let result = imageDBInteractor.saveImage(image, searchId: searchId, sortId: sortId, type: Image.self)
            continuation.resume(returning: result)
        }
    }
    
    func getImages(searchId: String) async -> [ImageType]? {
        await withCheckedContinuation { continuation in
            let result = imageDBInteractor.getImages(searchId: searchId, type: Image.self)
            continuation.resume(returning: result)
        }
    }
    
    func checkImagesAreCached(searchId: String) async -> Bool? {
        await withCheckedContinuation { continuation in
            let result = imageDBInteractor.checkImagesAreCached(searchId: searchId)
            continuation.resume(returning: result)
        }
    }
    
    func deleteAllImages() async {
        imageDBInteractor.deleteAllImages()
    }
}

extension DefaultImageRepository {
    func toTestPrepareImages(_ imagesData: Data?) -> [Image]? {
        prepareImages(imagesData)
    }
}
