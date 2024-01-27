//
//  ImageRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol ImageRepository {
    typealias ImagesDataResult = Result<Data, NetworkError>
    
    /* Can be used together with or instead of async methods:
    func searchImages(_ imageQuery: ImageQuery, completionHandler: @escaping (ImagesDataResult) -> Void) -> Cancellable?
    func prepareImages(_ imageData: Data, completionHandler: @escaping (Images?) -> Void)
    func getImage(url: URL, completionHandler: @escaping (Data?) -> Void) -> Cancellable?
    
    func saveImage(_ image: Image, searchId: String, sortId: Int, completionHandler: @escaping (Bool?) -> Void)
    func getImages(searchId: String, completionHandler: @escaping ([Image]?) -> Void)
    func checkImagesAreCached(searchId: String, completionHandler: @escaping (Bool?) -> Void)
    func deleteAllImages()
     */
    
    func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult
    func prepareImages(_ imageData: Data) async -> Images?
    func getImage(url: URL) async -> Data?
    
    func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool?
    func getImages(searchId: String) async -> [Image]?
    func checkImagesAreCached(searchId: String) async -> Bool?
    func deleteAllImages() async
}
