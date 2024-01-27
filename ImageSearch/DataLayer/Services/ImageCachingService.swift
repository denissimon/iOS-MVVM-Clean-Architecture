//
//  ImageCachingService.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/02/2024.
//

import Foundation

protocol ImageCachingService {
    var checkingInProgress: Bool { get }
    var idsToGetFromCache: Set<String> { get }
    var didProcess: Event<[ImageSearchResults]> { get }
    func cacheIfNecessary(_ data: [ImageSearchResults]) async
    func getCachedImages(searchId: String) async -> [Image]?
}
