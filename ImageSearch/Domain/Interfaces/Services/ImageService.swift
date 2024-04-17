import Foundation

protocol ImageService {
    func searchImages(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>?) async throws -> [Image]?
    func getBigImage(for image: Image) async -> Data?
}
