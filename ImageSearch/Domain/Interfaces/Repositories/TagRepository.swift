import Foundation

protocol TagRepository {
    func getHotTags() async -> Result<TagsType, CustomError>
}
