//
//  AppDelegate.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private(set) var dependencyContainer = DIContainer()
    private(set) var coordinator: AppCoordinator?
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        coordinator = AppCoordinator(dependencyContainer: dependencyContainer)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = coordinator?.navigationController
        window?.makeKeyAndVisible()
        
        coordinator?.start(completionHandler: nil)
        
        return true
    }
}
