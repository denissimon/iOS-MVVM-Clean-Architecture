//
//  AppCoordinator.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import UIKit

// Handles the app's flow
class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    lazy var navigationController = UINavigationController()
    let dependencyContainer: DIContainer
        
    // MARK: - Initializer
    init(dependencyContainer: DIContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    // MARK: - Methods
    func start(completionHandler: CoordinatorStartCompletionHandler?) {
        // We can use MainCoordinator as a coordinator for the entire app, as well as for a first tab (with a separate UINavigationController each) or even just for an app feature such as ImageFeature (in this case it's better to rename MainCoordinator to the feature name, and to move it to the feature folder)
        let mainCoordinator = dependencyContainer.makeMainCoordinator(navigationController: navigationController)
        mainCoordinator.start(completionHandler: nil)
    }
}

