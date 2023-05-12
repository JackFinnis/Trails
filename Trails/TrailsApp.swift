//
//  TrailsApp.swift
//  Trails
//
//  Created by Jack Finnis on 16/02/2023.
//

import SwiftUI
import FirebaseCore

let NAME = "UK Walks"
let SIZE = 44.0
let EMAIL = "jack.finnis@icloud.com"
let APP_URL = URL(string: "https://apps.apple.com/app/id6446465966")!

@main
struct TrailsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
