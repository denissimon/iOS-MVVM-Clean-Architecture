import Foundation

protocol ImageCachingService: Actor {
    var checkingInProgress: Task<Void, Never>? { get }
    var searchIdsToGetFromCache: Set<String> { get }
    var didProcess: Event<[ImageSearchResults]> { get }
    func cacheIfNecessary(_ data: [ImageSearchResults]) async
    func getCachedImages(searchId: String) async -> [Image]?
}
