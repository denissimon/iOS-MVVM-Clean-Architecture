import Foundation

protocol TagRepository {
    typealias TagsResult = Result<TagsType, AppError>
    
    func getHotTags() async -> TagsResult
}
