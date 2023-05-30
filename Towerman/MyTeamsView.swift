//
//  MyTeamsView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-21.
//

import SwiftUI
//import GoogleSignInSwift

struct MyTeamsView: View {
    @Binding var screen: AppScreen
    let loadTeams: () -> Void
    
    @EnvironmentObject var teamsManager: TeamsManager
    @EnvironmentObject var userAuth: UserAuthModel
    @EnvironmentObject var server: ServerModel
    
    @State private var inCreateTeam = false
    @State private var isLoading = false
    @State private var cellHeight: CGFloat = 100
    
    let layout = [
        GridItem(.adaptive(minimum: 200)),
    ]
    
    var body: some View {
        
        VStack {
//            Spacer()
            
            if !inCreateTeam {
                HStack {
                    Text("Towerman")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.title)
                        .onTapGesture {
                            userAuth.requestTeamScopes { _ in
                                
                            }
                        }
                    
                    Spacer()
                    if userAuth.isLoggedIn {
                        VStack(alignment: .trailing) {
                            Group {
                                Text("Signed in as ") +
                                Text(userAuth.givenName)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .font(.body)
                            
                            Button(action: { userAuth.signOut(); teamsManager.unloadTeams() }) {
                                Text("Sign out")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding(8)
                            }
                            .background(AppColors.contrast)
                            .cornerRadius(8)
                        }
                        .transition(.move(edge: .trailing))
                    }
                }
                .padding(.top, 12)
            }
            
            if userAuth.isLoggedIn {
                if inCreateTeam {
                    CreateTeamView(inCreateTeam: $inCreateTeam, teamsManager: teamsManager)
                } else if teamsManager.hasLoaded {
                    ScrollView(showsIndicators: false) {
                        
                        LazyVGrid(columns: layout, alignment: .center) {
                            ForEach(teamsManager.teams) { team in
                                TeamView(team: team, isOwner: team.owner == userAuth.email) {
                                    server.setTeamsManager(manager: teamsManager)
                                    teamsManager.select(team.id)
                                    change($screen, to: .modeSelect)
                                    userAuth.getUidToken { token in
                                        guard let token = token else {
                                            teamsManager.select(nil)
                                            change($screen, to: .myTeams)
                                            return
                                        }
                                        server.auth(token: token, teamId: team.id) { authTokenResult in
                                            if authTokenResult.success {
                                                server.connect(authToken: authTokenResult.data!)
                                            } else {
                                                teamsManager.select(nil)
                                                change($screen, to: .myTeams)
                                            }
                                        }
                                    }
                                }
                                .overlay {
                                    Group {
                                        if team.id == teamsManager.teams[0].id {
                                            GeometryReader { geo in
                                                Color.clear.onAppear {
                                                    cellHeight = geo.size.height
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if !teamsManager.teams.isEmpty {
                                AddTeamView(height: cellHeight) {
                                    inCreateTeam = true
                                }
                            }
                        }
                        if teamsManager.teams.isEmpty {
                            AddTeamView(height: cellHeight) {
                                inCreateTeam = true
                            }
                                .padding(.bottom, 32)
                            Text("You have not been added to any teams")
                        }
                    }
                    .transition(.scale)
                    
                    SecondaryButton(title: "Refresh", icon: "arrow.clockwise", background: AppColors.secondary) {
                        loadTeams()
                    }
                } else {
                    Spacer()
                }
            } else {
                SignInView(title: "Continue with Google", logo: "google-logo", info: "Towerman uses your Google account to easily sign you in.") {
                    userAuth.signIn() {
                        userAuth.getUidToken { token in
                            guard let token = token else {
                                userAuth.signOut()
                                return
                            }
                            server.signIn(email: userAuth.email, name: userAuth.givenName, token: token) { result in
                                if !result.success {
                                    DispatchQueue.main.async {
                                        print("Backend error")
//                                        userAuth.signOut()
                                    }
                                }
                                print(result.success)
                            }
                        }
                    }
                }
                .transition(.scale)
            }
        }
        .padding(UIDevice.isIPad ? 32 : 0)

    }
}

private struct SignInView: View {
    let title: String
    let logo: String
    let info: String
    let action: () -> Void
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: action) {
                HStack {
                    Image(logo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)

                    Text(title)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(8)
                }
                .padding(12)
            }
            .background(AppColors.contrast)
            .cornerRadius(8)
            .shadow(radius: 8)
            .padding(.bottom, 12)
            
            Text(info)
                        
            Spacer()
        }
        .padding(.horizontal, 12)
    }
}

private struct CreateTeamView: View {
    @Binding var inCreateTeam: Bool
    @ObservedObject var teamsManager: TeamsManager
    
    @EnvironmentObject var userAuth: UserAuthModel
    @EnvironmentObject var server: ServerModel
    @State private var teamName = ""
    @FocusState private var teamNameFocus: Bool
    @State private var inAuthorizeDrive = false
    @State private var inAddMembers = false
    
    @State private var keyboardActive = false
    var body: some View {
        let onName = {
            if isValidText(teamName) {
                withAnimation(Animation.linear(duration: 0.2)) {
                    inAddMembers = true
                    teamNameFocus = false
                    
                    teamsManager.create(name: teamName, owner: Team.Member(
                        name: userAuth.givenName,
                        email: userAuth.email,
                        isCapturer: true
                    ))
                }
            }
        }
        
        VStack {
            Text("Create Team")
                .font(.title2)
                .fontWeight(.bold)
            
            if !inAuthorizeDrive && !inAddMembers {
                Group {
                    TextField("Name", text: $teamName)
                        .focused($teamNameFocus)
                        .frame(maxWidth: UIScreen.screenWidth * 0.7)
                        .submitLabel(.done)
                        .ignoresSafeArea(.keyboard)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            onName()
                        }
                        .padding(8)
                        .background(AppColors.contrast)
                        .cornerRadius(8)
                    //                    .transition(.scale)
                        .onAppear {
                            teamNameFocus = true
                        }
                    
                    HStack {
                        Spacer()
                        SecondaryButton(title: "CANCEL", icon: "xmark", background: AppColors.contrast, action: {
                            withAnimation(Animation.linear(duration: 0.2)) {
                                teamNameFocus = false
                                teamName = ""
                                inCreateTeam = false
                            }
                        })
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 12)
                        Spacer()
                        
                        SecondaryButton(title: "NEXT", icon: "checkmark", background: isValidText(teamName) ? AppColors.secondary : AppColors.contrast, action: {
                            onName()
                        })
                        //                    .transition(.scale.combined(with: .opacity))
                        
                        Spacer()
                    }
                }
                .transition(.move(edge: .leading))
            } else if inAddMembers {
                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        TeamMembersView(
                            isOwner: true,
                            expandable: false,
                            teamsManager: teamsManager,
                            add: { member in teamsManager.add(member: member) },
                            remove: { email in teamsManager.remove(email: email) },
                            setCapturer: { email in teamsManager.setCapturer(to: email) }
                        ) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(Animation.linear(duration: 0.2)) {
                                    proxy.scrollTo("end", anchor: .bottom)
                                }
                            }
                        }
                        .onReceive(keyboardPublisher) { isActive in
                            if isActive {
                                keyboardActive = true
                            } else {
                                withAnimation(Animation.linear(duration: 0.2)) {
                                    keyboardActive = false
                                }
                            }
                        }
                        Divider()
                            .frame(height: 1)
                            .background(.white.opacity(0.8))
                            .padding(.bottom, 32)
                            .id("end")
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                Spacer()
                
                if !keyboardActive {
                    HStack {
                        SecondaryButton(title: "CANCEL", icon: "xmark", background: AppColors.contrast, action: {
                            teamsManager.destroy(teamsManager.selectedTeam?.id ?? "")
                            withAnimation(Animation.linear(duration: 0.2)) {
                                inCreateTeam = false
                            }
                        })
                        .transition(.scale.combined(with: .opacity))
                        
                        Spacer()
                        
                        SecondaryButton(title: "NEXT", icon: "checkmark", background: isValidText(teamName) ? AppColors.secondary : AppColors.contrast, action: {
                            withAnimation(Animation.linear(duration: 0.2)) {
                                inAddMembers = false
                                inAuthorizeDrive = true
                            }
                        })
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            } else {
                
                Group {
                    SignInView(title: "Authorize Google Drive", logo: "drive-logo", info: "Towerman requires authorization to backup team photos to your Google Drive.") {
                        userAuth.requestTeamScopes { OAuthToken in
                            guard let OAuthToken = OAuthToken else { return }
                            userAuth.getUidToken { token in
                                guard let token = token else { return }
                                server.createTeam(
                                    token: token,
                                    name: teamName,
                                    members: teamsManager.selectedTeam?.members ?? [],
                                    OAuthRefreshToken: OAuthToken,
                                    capturer: (teamsManager.selectedTeam?.members ?? []).first { x in x.isCapturer }) { result in
                                        if result.success {
                                            teamsManager.setId(to: result.data!)
                                            withAnimation(Animation.linear(duration: 0.2)) {
                                                inCreateTeam = false
                                            }
                                        } else {
                                            print(result.error!)
                                        }
                                    }
                            }
                        }
                    }
//                    .onAppear {
//                        if userAuth.teamScopesGranted {
//                            withAnimation(Animation.linear(duration: 0.2)) {
//                                inCreateTeam = false
//                            }
//                        }
//                    }
                    
                    HStack {
                        SecondaryButton(title: "CANCEL", icon: "xmark", background: AppColors.contrast, action: {
                            teamsManager.destroy(teamsManager.selectedTeam?.id ?? "")
                            withAnimation(Animation.linear(duration: 0.2)) {
                                inCreateTeam = false
                            }
                        })
                        Spacer()
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
}

private struct TeamView: View {
    let team: Team
    let isOwner: Bool
    let action: () -> Void
    var body: some View {
        VStack {
            Text(team.name)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Divider()
                .frame(height: 2)
                .background(.gray)
            
            Group {
                Text("Owned by ") +
                Text(isOwner ? "me" : team.members.first { x in x.email == team.owner }!.name())
                    .fontWeight(.semibold)
            }
            
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(AppColors.contrast)
        .cornerRadius(8)
//        .border(team.color, width: 4)
//        .cornerRadius(8)
        .onTapGesture(perform: action)
        
    }
}

struct AddTeamView: View {
    let height: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(Animation.linear(duration: 0.2)) {
                action()
            }
        }) {
            HStack {
                Text("Create Team")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold, design: .default))
            }
            .foregroundColor(.white)
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(AppColors.contrast)
            .cornerRadius(8)
        }
    }
}

//private struct Team: Identifiable {
//    let Colors = [
//        Color(red: 0.65, green: 0.12, blue: 0.21),
//        Color(red: 0.12, green: 0.65, blue: 0.21),
//        Color(red: 0.21, green: 0.12, blue: 0.65),
//    ]
//    init(_ name: String, color: Int, isOwner: Bool = false, owner: String = "Derek C") {
//        self.name = name
//        self.isOwner = isOwner
//        self.owner = owner
//        self.color = Colors[color]
//    }
//    let name: String
//    let isOwner: Bool
//    let owner: String
//    let color: Color
//    var id: String { name }
//
//}
