import Foundation

protocol GetHotTagsUseCase {
    func execute() async -> Result<Tags, AppError>
}

class DefaultGetHotTagsUseCase: GetHotTagsUseCase {
    
    private let tagRepository: TagRepository
    
    init(tagRepository: TagRepository) {
        self.tagRepository = tagRepository
    }
    
    func execute() async -> Result<Tags, AppError> {
        let result = await tagRepository.getHotTags()
        switch result {
        case .success(let tagsType):
            return .success(tagsType as! Tags)
        case .failure(let error):
            return .failure(error)
        }
    }
}
