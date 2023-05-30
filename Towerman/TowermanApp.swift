//
//  TowermanApp.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-09.
//

import SwiftUI
import GoogleSignIn
import Firebase
import OAuthSwift

@main
struct TowermanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var teamsManager = TeamsManager.initial()
    @StateObject var userAuth: UserAuthModel = UserAuthModel()
    @StateObject var server: ServerModel = ServerModel()
    @StateObject var photoCache: PhotoCache = PhotoCache()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    if !GIDSignIn.sharedInstance.handle(url)  {
                        OAuthSwift.handle(url: url)
                    }
                }
                .onAppear {
                    userAuth.restoreSignIn()
                    server.setPhotoCache(cache: photoCache)
                }
                .environmentObject(teamsManager)
                .environmentObject(userAuth)
                .environmentObject(server)
                .environmentObject(photoCache)
        }
    }
//
//    /// set orientations you want to be allowed in this property by default
//    var orientationLock = UIInterfaceOrientationMask.landscapeRight
//
//    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//            return self.orientationLock
//    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
