import Foundation

class DefaultImageRepository: ImageRepository {
    
    let apiInteractor: APIInteractor
    let imageDBInteractor: ImageDBInteractor
    
    init(apiInteractor: APIInteractor, imageDBInteractor: ImageDBInteractor) {
        self.apiInteractor = apiInteractor
        self.imageDBInteractor = imageDBInteractor
    }
    
    func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult {
        let endpoint = FlickrAPI.search(imageQuery)
        do {
            let result = try await apiInteractor.request(endpoint)
            return .success(result)
        } catch {
            if error is AppError {
                return .failure(error as! AppError)
            }
            return .failure(AppError.unexpected(error))
        }
    }
    
    // A pure transformation of the data (a pure function within the impure context)
    func prepareImages(_ imagesData: Data?) async -> [Image]? {
        do {
            guard
                let imagesData = imagesData, !imagesData.isEmpty,
                let resultsDictionary = try JSONSerialization.jsonObject(with: imagesData) as? [String: AnyObject],
                let stat = resultsDictionary["stat"] as? String
                else { return nil }

            if stat != "ok" { return nil }
            
            guard
                let container = resultsDictionary["photos"] as? [String: AnyObject],
                let photos = container["photo"] as? [[String: AnyObject]]
                else { return nil }
            
            let imagesFound: [Image] = photos.compactMap { imageDict in
                return Image(flickrParams: imageDict)
            }
            
            guard !imagesFound.isEmpty else { return nil }
            
            return imagesFound
        } catch {
            return nil
        }
    }
    
    func getImage(url: URL) async -> Data? {
        do {
            return try await apiInteractor.fetchFile(url: url)
        } catch {
            return nil
        }
    }
    
    func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool? {
        await imageDBInteractor.saveImage(image, searchId: searchId, sortId: sortId, type: Image.self)
    }
    
    func getImages(searchId: String) async -> [ImageType]? {
        await imageDBInteractor.getImages(searchId: searchId, type: Image.self)
    }
    
    func checkImagesAreCached(searchId: String) async -> Bool? {
        await imageDBInteractor.checkImagesAreCached(searchId: searchId)
    }
    
    func deleteAllImages() async {
        await imageDBInteractor.deleteAllImages()
    }
}
