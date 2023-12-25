//
//  ImageRepository.swift
//  ImageSearch
//
//  Created by Denis Simon on 12/25/2023.
//

import Foundation

protocol ImageRepository {
    typealias ImagesDataResult = Result<Data, NetworkError>
    typealias ImageDataResult = ImagesDataResult
    
    func searchImages(_ imageQuery: ImageQuery, completionHandler: @escaping (ImagesDataResult) -> Void) -> Cancellable?
    func prepareImages(_ imageData: Data, completionHandler: @escaping (Images?) -> Void)
    func getLargeImage(url: URL, completionHandler: @escaping (ImageDataResult) -> Void) -> Cancellable?
}
