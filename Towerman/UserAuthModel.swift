//
//  UserAuthModel.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-09.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import OAuthSwift


private let teamScopes = [
    "https://www.googleapis.com/auth/drive.file",
//    "https://www.googleapis.com/auth/drive.resource"
]

class UserAuthModel: ObservableObject {
    
    @Published var givenName: String = ""
    @Published var email: String = ""
    @Published var profilePicUrl: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var teamScopesGranted = false
    
    var googleUser: GIDGoogleUser?
    
    private var oauth2Handle: OAuthSwiftRequestHandle? = nil
    
    init(){
        check()
    }
    
    func checkStatus(){
        if(GIDSignIn.sharedInstance.currentUser != nil) {
            let user = GIDSignIn.sharedInstance.currentUser
            guard let user = user else { return }
            
//            self.googleDriveService.authorizer = user.fetcherAuthorizer
            self.googleUser = user
            //        clientId: com.googleusercontent.apps.721925047966-6c8n4oji9q8e46t20dd5opi5m6m6ag78
            //            self.googleUser?.accessToken
            //            self.googleUser?.refreshToken
//            setRootFolder(service: googleDriveService, user: user) { }
            
            let givenName = user.profile?.givenName
            let profilePicUrl = user.profile!.imageURL(withDimension: 100)!.absoluteString
            self.givenName = givenName ?? ""
            self.profilePicUrl = profilePicUrl
            self.email = user.profile?.email ?? ""
            self.teamScopesGranted = teamScopes.allSatisfy { x in user.grantedScopes?.contains(x) ?? false }
            withAnimation(Animation.linear(duration: 0.2)) {
                self.isLoggedIn = true
            }
        } else {
            withAnimation(Animation.linear(duration: 0.2)) {
                self.isLoggedIn = false                
            }
            self.givenName = "Not Logged In"
            self.email = "Not Logged In"
            self.profilePicUrl =  ""
            self.googleUser = nil
            self.teamScopesGranted = false
//            self.googleDriveService.authorizer = nil
        }
    }
    
    func check(){
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
            }
            
            self.checkStatus()
        }
    }
    
    func requestTeamScopes(_ onComplete: @escaping (String?) -> Void) {
//        GoogleAuthProvider.
        if self.teamScopesGranted {
            print(self.googleUser!.accessToken.tokenString)
            print(self.googleUser!.refreshToken.tokenString)
            onComplete(self.googleUser?.refreshToken.tokenString)
            return
        }
        print("Requesting team scopes...")
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        
//        let signInConfig = GIDConfiguration(clientID: "721925047966-6c8n4oji9q8e46t20dd5opi5m6m6ag78.apps.googleusercontent.com")
        
        self.googleUser?.addScopes(teamScopes, presenting: presentingViewController) { user, error in
            
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
            }
            self.checkStatus()
            if let user = user {
                onComplete(user.user.refreshToken.tokenString)
            } else {
                onComplete(nil)
            }
        }
    }
    
//    func requestOAuth() {
//        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
//
//        //1
//        let oauthswift = OAuth2Swift(
//          consumerKey:    "721925047966-6c8n4oji9q8e46t20dd5opi5m6m6ag78.apps.googleusercontent.com",
//          consumerSecret: "",        // No secret required
//          authorizeUrl:   "https://accounts.google.com/o/oauth2/auth",
//          accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
//          responseType:   "code"
//        )
//
//        oauthswift.allowMissingStateCheck = true
//        //2
//        oauthswift.authorizeURLHandler = SafariURLHandler(viewController: presentingViewController, oauthSwift: oauthswift)
//
//        guard let rwURL = URL(string: "com.noaha.Towerman:/oauth2Callback") else { return }
//
//        //3
//        oauth2Handle = oauthswift.authorize(withCallbackURL: rwURL, scope: "https://www.googleapis.com/auth/drive.file", state: "") { result in
//            switch result {
//            case .success(let (credential, response, parameters)):
////                print(credential.)
//                print(credential.oauthToken)
//                // Do your request
//            case .failure(let error):
//                print(error.localizedDescription)
//                print(error.description)
//            }
//        }
//    }
    
    func signIn(onSuccess: @escaping () -> Void) {
        print("Signing in...")
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {return}
        
        
//        let signInConfig = GIDConfiguration(clientID: "721925047966-6c8n4oji9q8e46t20dd5opi5m6m6ag78.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: "Sign in with your Google Account") { user, error in
                self.checkStatus()
                if let error = error {
                    self.errorMessage = "error: \(error.localizedDescription)"
                } else if let user = user?.user {
                    let credential = GoogleAuthProvider.credential(withIDToken: user.idToken!.tokenString,
                                                                   accessToken: user.accessToken.tokenString)
                    Auth.auth().signIn(with: credential) { result, error in
                        if ((result?.user) != nil) {
                            onSuccess()
                        }
                        if let error = error {
                            print(error)
                        }
                    }
                }
            }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
        
        self.checkStatus()
    }
    
    func restoreSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                let credential = GoogleAuthProvider.credential(withIDToken: user.idToken!.tokenString,
                                                               accessToken: user.accessToken.tokenString)
                Auth.auth().signIn(with: credential) { result, error in
                }
            }
        }
    }
    
    func getUidToken(onComplete: @escaping (_ token: String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            onComplete(nil)
            return
        }
        user.getIDTokenResult { token, error in
            onComplete(token?.token)
        }
    }
}
