//
//  AppDelegate.swift
//  Zone25
//
//  Created by Michael Kühweg on 02.01.18.
//  Copyright © 2018 Michael Kühweg. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        viewController()?.stopRefreshTimer()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        viewController()?.stopRefreshTimer()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        viewController()?.startRefreshTimer()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        viewController()?.startRefreshTimer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    private func viewController() -> ViewController? {
        return self.window?.rootViewController?.presentedViewController
            as? ViewController
    }

}

