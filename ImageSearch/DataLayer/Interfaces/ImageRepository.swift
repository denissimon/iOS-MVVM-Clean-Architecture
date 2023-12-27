//
//  ImageRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol ImageRepository {
    typealias ImagesDataResult = Result<Data, NetworkError>
    
    // Can be used together with or instead of async methods:
    //func searchImages(_ imageQuery: ImageQuery, completionHandler: @escaping (ImagesDataResult) -> Void) -> Cancellable?
    //func prepareImages(_ imageData: Data, completionHandler: @escaping (Images?) -> Void)
    //func getLargeImage(url: URL, completionHandler: @escaping (Data?) -> Void) -> Cancellable?
    
    func searchImages(_ imageQuery: ImageQuery) async -> ImagesDataResult
    func prepareImages(_ imageData: Data) async -> Images?
    func getLargeImage(url: URL) async -> Data?
}
