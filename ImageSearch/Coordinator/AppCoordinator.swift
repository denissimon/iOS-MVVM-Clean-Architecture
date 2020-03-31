//
//  AppCoordinator.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit

protocol ShowDetailsCoordinatorDelegate: class {
    func showDetails(of image: Image, header: String, from viewController: UIViewController)
    func hideDetails(from viewController: UIViewController)
}

class AppCoordinator: AppCoordinatorProtocol {
    
    var rootNavigationController: UINavigationController!
    let networkService: NetworkService!
    let window: UIWindow?

    init(window: UIWindow?) {
        self.window = window
        networkService = NetworkService()
    }
    
    func start() {
        guard let window = window else { return }
        
        rootNavigationController = UINavigationController(rootViewController: getImageSearchController())
        window.rootViewController = rootNavigationController
        window.makeKeyAndVisible()
    }
    
    func getImageSearchController() -> ImageSearchViewController {
        let imageSearchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: AppConstants.Storyboard.ImageSearchVCIdentifier) as! ImageSearchViewController
        let viewModel = ImageSearchViewModel(networkService: networkService)
        imageSearchVC.viewModel = viewModel
        imageSearchVC.coordinatorDelegate = self
        return imageSearchVC
    }
}

extension AppCoordinator: ShowDetailsCoordinatorDelegate {
    
    func showDetails(of image: Image, header: String, from viewController: UIViewController) {
        let imageDetailsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: AppConstants.Storyboard.ImageDetailsVCIdentifier) as! ImageDetailsViewController
        let viewModel = ImageDetailsViewModel(networkService: networkService, tappedImage: image, headerTitle: header)
        imageDetailsVC.viewModel = viewModel
        imageDetailsVC.coordinatorDelegate = self
        
        let imageDetailsNC = UINavigationController(rootViewController: imageDetailsVC)
        viewController.show(imageDetailsNC, sender: nil)
    }
    
    func hideDetails(from viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

