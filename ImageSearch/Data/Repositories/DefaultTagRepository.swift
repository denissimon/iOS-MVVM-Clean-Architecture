import Foundation

class DefaultTagRepository: TagRepository {
    
    let apiInteractor: APIInteractor
    
    init(apiInteractor: APIInteractor) {
        self.apiInteractor = apiInteractor
    }
    
    func getHotTags() async -> Result<TagsType, AppError> {
        let endpoint = FlickrAPI.getHotTags()
        do {
            let tags = try await apiInteractor.request(endpoint, type: Tags.self)
            if tags.stat != "ok" {
                return .failure(AppError.server())
            }
            return .success(tags)
        } catch {
            if error is AppError {
                return .failure(error as! AppError)
            }
            return .failure(AppError.unexpected(error))
        }
    }
}
