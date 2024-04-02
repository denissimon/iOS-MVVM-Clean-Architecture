//
//  ImageRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol ImageRepository {
    typealias ImagesDataResult = Result<Data?, NetworkError>
    
    func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult
    func prepareImages(_ imageData: Data?) async -> [Image]?
    func getImage(url: URL) async -> Data?
    
    func saveImage(_ image: Image, searchId: String, sortId: Int) async -> Bool?
    func getImages(searchId: String) async -> [Image]?
    func checkImagesAreCached(searchId: String) async -> Bool?
    func deleteAllImages() async
}
