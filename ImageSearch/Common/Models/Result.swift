//
//  Result.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import Foundation

enum Result<T> {
    case done(T)
    case error((Swift.Error?, Int?)) // (error description, status code)
}
