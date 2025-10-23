//
//  AppDelegate.swift
//  DemoAuthCloudApper
//
//  Created by Sanzid on 23/10/25.
//

import AppAuth
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)

        // 2. Load your Main.storyboard
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

        // 3. Get the starting view controller from the storyboard
        guard let initialViewController = mainStoryboard.instantiateInitialViewController() else {
            fatalError("Could not instantiate initial view controller from Main.storyboard")
        }

        // 4. Set it as the root
        window?.rootViewController = initialViewController

        // 5. Show the window
        window?.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Pass the URL to the active AppAuth session
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let fragment = components?.fragment, components?.query == nil {
            components?.query = fragment
            components?.fragment = nil
        }

        let urlToPass = components?.url ?? url

        if let authorizationFlow = AuthService.shared.currentAuthorizationFlow,
           authorizationFlow.resumeExternalUserAgentFlow(with: urlToPass) {
            AuthService.shared.currentAuthorizationFlow = nil
            return true
        }

        return false
    }
}
