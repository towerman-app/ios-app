//
//  ContentView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-11.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var screen: AppScreen = .myTeams
    @State private var inMyTeamsView = false
    
//    @StateObject private var gameManager = GameManager()
    @EnvironmentObject var userAuth: UserAuthModel
    @EnvironmentObject var server: ServerModel
    @EnvironmentObject var teamsManager: TeamsManager
    
        
    var body: some View {
        let loadTeams = {
            teamsManager.isLoading = true
            userAuth.getUidToken { token in
                guard let token = token else { teamsManager.isLoading = false; return }
                server.getTeams(token: token) { result in
                    if result.success {
                        teamsManager.loadTeams(result.data!)
                        
                    } else {
                        print(result.error!)
                    }
                    DispatchQueue.main.async {
                        teamsManager.isLoading = false                        
                    }
                }
            }
        }
        
        ZStack {
            AppColors.primary.edgesIgnoringSafeArea(.all)
                .zIndex(-1)
            
            switch screen {
            case .modeSelect:
                ModeSelectView(screen: $screen, changingToTeams: inMyTeamsView, teamsManager: teamsManager)
                
            case .myTeams:
//                ExpandedPlayView(onExit: {}, play: SeriesPlay(play: PlayData(quarter: 2, odk: "O", down: 2, distance: 7, startLine: 30, endLine: 36, series: 2, flagged: false), photos: [
//                    PlayData.PlayPhoto.dummy().toImage(),
//                    PlayData.PlayPhoto.dummy().toImage()
//                ]))
                MyTeamsView(screen: $screen, loadTeams: loadTeams)
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
                    .onAppear {
                        inMyTeamsView = true
                    }
                    .onDisappear {
                        inMyTeamsView = false
                    }

            case .tagging:
                TaggingView(screen: $screen, taggingManager: TaggingManager.inital(), uploadManager: UploadManager.initial())
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                
            case .viewing:
                ViewingView(screen: $screen)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                
            default:
                VStack {
                    Text("Are you lost?")
                    Button("Take me home") {
                        change($screen, to: .myTeams)
                    }
                }
            }
            
        }
        .preferredColorScheme(.dark)
        .overlay {
            if teamsManager.isLoading {
                Rectangle()
                    .foregroundColor(AppColors.contrast)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { auth, user in
                if user != nil {
                    loadTeams()
                } else {
                    DispatchQueue.main.async {
                        teamsManager.isLoading = false
                    }
                }
            }
        }
        .onChange(of: server.isConnected, perform: { isConnected in
            if isConnected || screen == .myTeams || screen == .login { return }
            print("Not connected")
            userAuth.getUidToken { token in
                guard let token = token else {
                    server.disconnect()
                    change($screen, to: .myTeams)
                    return
                }
                guard let id = teamsManager.selectedTeam?.id else {
                    server.disconnect()
                    change($screen, to: .myTeams)
                    return
                }
                server.auth(token: token, teamId: id) { authTokenResult in
                        if authTokenResult.success {
                            server.connect(authToken: authTokenResult.data!)
                        } else {
                            teamsManager.select(nil)
                            change($screen, to: .myTeams)
                        }
                }
            }
        })
    }
}



enum AppScreen {
    case login
    case myTeams
    case modeSelect
    case tagging
    case viewing
}

func change(_ screen: Binding<AppScreen>, to: AppScreen) {
    withAnimation(Animation.linear(duration: 0.1)) {
        screen.wrappedValue = to
    }
}

extension UIScreen {
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

