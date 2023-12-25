//
//  Cancellable.swift
//  CryptocurrencyInfo
//
//  Created by Denis Simon on 11/18/2023.
//

import Foundation

protocol NetworkCancellable {
    func cancel()
}

extension URLSessionDataTask: NetworkCancellable {}

protocol Cancellable {
    var isCancelled: Bool { get set }
    func cancel()
}

class RepositoryTask: Cancellable {
    var networkTask: NetworkCancellable?
    var isCancelled = false
    
    func cancel() {
        networkTask?.cancel()
        isCancelled = true
    }
}

