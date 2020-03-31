//
//  EndpointType.swift
//  ImageSearch
//
//  Created by Denis Simon on 03/09/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import Foundation

protocol EndpointType {
    var method: Method { get }
    var baseURL: String { get }
    var path: String { get }
    var constructedURL: URL? { get }
}
