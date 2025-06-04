import Foundation

protocol TagRepository: Sendable {
    func getHotTags() async -> Result<TagsType, CustomError>
}
