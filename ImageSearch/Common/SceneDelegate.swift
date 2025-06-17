import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    private(set) var dependencyContainer = DIContainer()
    private(set) var coordinator: AppCoordinator?
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        coordinator = AppCoordinator(dependencyContainer: dependencyContainer)
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = coordinator?.navigationController
        self.window = window
        window.makeKeyAndVisible()
        
        coordinator?.start(completionHandler: nil)
    }
}
