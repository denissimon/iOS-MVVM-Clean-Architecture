import Foundation

protocol TagRepository {
    typealias TagsResult = Result<Tags, NetworkError>
    
    func getHotTags() async -> TagsResult
}
