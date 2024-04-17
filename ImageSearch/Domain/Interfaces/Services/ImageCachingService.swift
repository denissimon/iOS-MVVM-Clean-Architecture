import Foundation

protocol ImageCachingService {
    var checkingInProgress: Bool { get }
    var searchIdsToGetFromCache: Set<String> { get }
    var didProcess: Event<[ImageSearchResults]> { get }
    func cacheIfNecessary(_ data: [ImageSearchResults]) async
    func getCachedImages(searchId: String) async -> [Image]?
}
