//
//  AppCoordinator.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit

protocol ShowDetailsCoordinatorDelegate: class {
    func showDetailsScreen(of image: Image, header: String, from viewController: UIViewController)
    func hideDetailsScreen(from viewController: UIViewController)
}

protocol HotTagsListCoordinatorDelegate: class {
    func showListScreen(from viewController: UIViewController)
    func hideListScreen(tappedTag: String?, from viewController: UIViewController)
}

class AppCoordinator: AppCoordinatorProtocol {
    
    var rootNavigationController: UINavigationController!
    let networkService: NetworkService!
    let window: UIWindow?

    init(window: UIWindow?, networkService: NetworkService) {
        self.window = window
        self.networkService = networkService
    }
    
    func start() {
        guard let window = window else { return }
        
        rootNavigationController = UINavigationController(rootViewController: getImageSearchController())
        window.rootViewController = rootNavigationController
        window.makeKeyAndVisible()
    }
    
    private func getImageSearchController() -> ImageSearchViewController {
        let imageSearchVC = UIStoryboard(name: "ImageSearch", bundle: nil).instantiateViewController(withIdentifier: Constants.Storyboards.imageSearchVCIdentifier) as! ImageSearchViewController
        let viewModel = ImageSearchViewModel(networkService: networkService)
        imageSearchVC.viewModel = viewModel
        imageSearchVC.showDetailsCoordinatorDelegate = self
        imageSearchVC.hotTagsListCoordinatorDelegate = self
        return imageSearchVC
    }
}

extension AppCoordinator: ShowDetailsCoordinatorDelegate {
    
    func showDetailsScreen(of image: Image, header: String, from viewController: UIViewController) {
        let imageDetailsVC = UIStoryboard(name: "ImageDetails", bundle: nil).instantiateViewController(withIdentifier: Constants.Storyboards.imageDetailsVCIdentifier) as! ImageDetailsViewController
        let viewModel = ImageDetailsViewModel(networkService: networkService, tappedImage: image, headerTitle: header)
        imageDetailsVC.viewModel = viewModel
        imageDetailsVC.coordinatorDelegate = self
        
        let imageDetailsNC = UINavigationController(rootViewController: imageDetailsVC)
        viewController.show(imageDetailsNC, sender: nil)
    }
    
    func hideDetailsScreen(from viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension AppCoordinator: HotTagsListCoordinatorDelegate {
    func showListScreen(from viewController: UIViewController) {
        let hotTagsListVC = UIStoryboard(name: "HotTagsList", bundle: nil).instantiateViewController(withIdentifier: Constants.Storyboards.hotTagsListVCIdentifier) as! HotTagsListViewController
        let viewModel = HotTagsListViewModel(networkService: networkService)
        hotTagsListVC.viewModel = viewModel
        hotTagsListVC.coordinatorDelegate = self
        
        viewController.navigationController?.pushViewController(hotTagsListVC, animated: true)
    }
    
    func hideListScreen(tappedTag: String?, from viewController: UIViewController) {
        if let tappedTag = tappedTag {
            let imageSearchVC = viewController.navigationController?.viewControllers.first as! ImageSearchViewController
            imageSearchVC.viewModel.searchFlickr(for: tappedTag)
        }
        viewController.navigationController?.popViewController(animated: true)
    }
}
