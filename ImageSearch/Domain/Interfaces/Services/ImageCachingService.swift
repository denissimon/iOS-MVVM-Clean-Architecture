import Foundation

protocol ImageCachingService: Actor {
    var cachingTask: Task<Void, Never>? { get }
    var searchIdsFromCache: Set<String> { get }
    var didProcess: Event<[ImageSearchResults]> { get }
    func cacheIfNecessary(_ data: [ImageSearchResults]) async
    func getCachedImages(searchId: String) async -> [Image]?
}
