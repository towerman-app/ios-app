//
//  SwiftUIView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-21.
//

import SwiftUI

struct ModeSelectView: View {
    @Binding var screen: AppScreen
    @State var changingToTeams: Bool
    @ObservedObject var teamsManager: TeamsManager
    @EnvironmentObject var server: ServerModel
    @EnvironmentObject var userAuth: UserAuthModel
    
    @State private var inSettingsView = false
//    @State private var isLoading = true
    
    @State private var gameName: String = ""
    @FocusState private var gameNameFocus: Bool
    @State private var isNamingGame = false
    @State private var confirmEndGame = false

    @State private var gameOverMessage = false
        
    var body: some View {
        
        let startGame = {
            if isValidText(gameName) {
                withAnimation(Animation.linear(duration: 0.2)) {
                    server.startGame(name: gameName)
//                    teamsManager.startGame(withName: gameName)
                    isNamingGame = false
                }
            }
        }
        VStack {
            Spacer()
            Text(teamsManager.selectedTeam?.name.uppercased() ?? "")
                .foregroundColor(.white)
                .fontWeight(.bold)
                .font(.title2)
            
            if gameOverMessage {
                VStack {
                    Text("The game has been marked as complete.")
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .font(.title3)
                    
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(AppColors.primary)
                .cornerRadius(8)
                .shadow(radius: 12)
                .onTapGesture {
                    withAnimation(Animation.linear(duration: 0.2)) {
                        gameOverMessage = false
                    }
                }
                .transition(.scale)
            }
            
            if let game = teamsManager.selectedTeam?.game {
                Spacer()
                HStack(spacing: 16) {
                    Text(game.name.uppercased())
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.title3)
                    
                    if teamsManager.owner()?.email ?? "" == userAuth.email {
                        Button(action: {
                            confirmEndGame = true
                        }) {
                            HStack {
                                Text("END GAME")
                                    .fontWeight(.bold)
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 20, weight: .semibold, design: .default))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(AppColors.secondary)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 32)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.8), radius: 8)
                .transition(.scale)
                .alert("End Game?", isPresented: $confirmEndGame) {
                    
                    Button("Cancel", role: .cancel) {
                        
                    }
                    Button("Confirm", role: .destructive) {
                        server.endGame()
                        server.photoCache?.clear()
                    }
                }
                
                Spacer()
                HStack(spacing: 16) {
                    if teamsManager.capturer()?.email ?? "" == userAuth.email {
                        ModeButton(action: {
                            server.startCapturing()
                            changingToTeams = false
                            change($screen, to: .tagging)
                            
                        }, title: "CAPTURE MODE", icon: "camera", disabled: teamsManager.capturing() != nil)
                    }
                    
                    ModeButton(action: {
                        server.startViewing()
                        server.requestPhotos()
                        changingToTeams = false
                        change($screen, to: .viewing)
                        
                    }, title: "VIEWING MODE", icon: "eye", disabled: false)
                }
                .padding(16)
                .transition(.scale)
                                
            } else {
                Spacer()
                
                if teamsManager.owner()?.email ?? "" == userAuth.email {
                    if !isNamingGame {
                        ModeButton(action: {
                            withAnimation(Animation.linear(duration: 0.2)) {
                                gameOverMessage = false
                                isNamingGame = true
                                gameNameFocus = true
                            }
                            
                        }, title: "START GAME", icon: "plus", disabled: false)
                        .frame(maxWidth: UIScreen.screenWidth / 2)
                        .transition(.scale)
                    } else {
                        TextField("Name", text: $gameName)
                            .focused($gameNameFocus)
                            .frame(maxWidth: UIScreen.screenWidth * 0.7)
                            .submitLabel(.done)
                            .ignoresSafeArea(.keyboard)
                            .multilineTextAlignment(.center)
                            .onSubmit { startGame() }
                            .padding(8)
                            .background(AppColors.contrast)
                            .cornerRadius(8)
                            .transition(.scale)
                    }
                } else {
                    Group {
                        Text("There's no game right now.\n Ask ") +
                        Text(teamsManager.owner()?._name ?? "the owner")
                            .fontWeight(.bold) +
                        Text(" to start one.")
                    }
                }
                Spacer()
            }
            
            Spacer()
            HStack(alignment: .top) {
                if isNamingGame {
                    Spacer()
                    SecondaryButton(title: "CANCEL", icon: "xmark", background: AppColors.contrast, action: {
                        withAnimation(Animation.linear(duration: 0.2)) {
                            isNamingGame = false
                            gameNameFocus = false
                            gameName = ""
                        }
                    })
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 12)
                    Spacer()
                    
                    SecondaryButton(title: "START", icon: "checkmark", background: isValidText(gameName) ? AppColors.secondary : AppColors.contrast, action: startGame)
                    .transition(.scale.combined(with: .opacity))

                    Spacer()
                } else {
                    SecondaryButton(title: "MY TEAMS", icon: "list.bullet", action: {
                        changingToTeams = true
                        teamsManager.select(nil)
                        change($screen, to: .myTeams)
                        server.disconnect()
                        
                    })
                    .transition(.scale.combined(with: .opacity))

                    Spacer()
                    if let text = teamsManager.capturing()?.name() {
                        Group {
                            Text(text)
                                .fontWeight(.bold) +
                            Text(" is capturing.")
                        }
                        .font(.body)
                        .transition(.move(edge: .bottom))
                        Spacer()
                    }
                    SecondaryButton(title: "SETTINGS", icon: "gearshape") {
                        withAnimation(Animation.linear(duration: 0.1)) {
                            inSettingsView = true
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(UIDevice.isIPad ? 32 : 0)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if isNamingGame {
                        withAnimation(Animation.linear(duration: 0.2)) {
                            isNamingGame = false
                            gameNameFocus = false
                            gameName = ""
                        }
                    }
                }
        }
        .overlay {
            if !server.isConnected {
                Rectangle()
                    .foregroundColor(AppColors.contrast)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                ProgressView()
                    .scaleEffect(1.2)
            }
        }
        .overlay {
            if inSettingsView {
                SettingsView(
                    exit: { withAnimation(Animation.linear(duration: 0.1)) { inSettingsView = false } },
                    teamsManager: teamsManager,
                    onSignOut: {
                        changingToTeams = true
                        teamsManager.select(nil)
                        change($screen, to: .myTeams)
                    }
                )
                    .transition(.move(edge: .bottom))
            }
        }
        .overlay {
            ErrorStackView(errors: server.errorStack)
        }
//        .onAppear {
//            
//            isLoading = changingToTeams
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                isLoading = false
//            }
//        }
        .onChange(of: server.isConnected) { connected in
            if !connected { return }
            server.requestPhotos()
            
        }
        .onChange(of: teamsManager.selectedTeam?.game == nil, perform: { isNil in
            if !isNil { return }
            withAnimation(Animation.linear(duration: 0.2)) {
                gameName = ""
                gameOverMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(Animation.linear(duration: 0.2)) {
                    gameOverMessage = false
                }
            }
        })
        .transition(.scale(scale: changingToTeams ? 0.7 : 1.3).combined(with: .opacity))
    }
}

private struct ModeButton: View {
    let action: () -> Void
    let title: String
    let icon: String
    let disabled: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(disabled ? AppColors.disabled : AppColors.secondary)
            .cornerRadius(12)
        }
        .disabled(disabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String
    let background: Color
    let action: () -> Void
    
    init(title: String, icon: String, background: Color = AppColors.contrast, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.background = background
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .font(.callout)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(minHeight: 50)
            .background(background)
            .cornerRadius(8)
        }
    }
}
