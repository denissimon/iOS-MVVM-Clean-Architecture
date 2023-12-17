//
//  Coordinator.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import UIKit

public typealias CoordinatorStartCompletionHandler = () -> ()

protocol Coordinator {
    var navigationController: UINavigationController { get }
    func start(completionHandler: CoordinatorStartCompletionHandler?)
}

