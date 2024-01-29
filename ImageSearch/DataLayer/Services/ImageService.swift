//
//  ImageService.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/28/2024.
//

import Foundation

protocol ImageService {
    func searchImages(_ imageQuery: ImageQuery, imagesLoadTask: Task<Void, Never>?) async throws -> [Image]?
}
