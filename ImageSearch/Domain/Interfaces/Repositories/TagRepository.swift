import Foundation

protocol TagRepository {
    typealias TagsResult = Result<TagsType, NetworkError>
    
    func getHotTags() async -> TagsResult
}
