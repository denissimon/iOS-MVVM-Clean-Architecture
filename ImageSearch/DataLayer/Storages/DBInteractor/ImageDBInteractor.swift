//
//  ImageDBInteractor.swift
//  ImageSearch
//
//  Created by Denis Simon on 01/02/2024.
//

import Foundation

// Result<Type, Error> can be used as another way to return the result in saveImage, getImages and getImageCount
protocol ImageDBInteractor {
    func saveImage<T: Codable>(_ image: T, searchId: String, sortId: Int, type: T.Type, completion: @escaping (Bool?) -> Void)
    func getImages<T: Codable>(searchId: String, type: T.Type, completion: @escaping ([T]?) -> Void)
    func getImageCount(searchId: String, completion: @escaping (Int?) -> Void)
    func deleteAllImages()
}
