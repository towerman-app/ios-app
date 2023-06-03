//
//  SettingsView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-03-03.
//

import SwiftUI

struct SettingsView: View {
    let exit: () -> Void
    @ObservedObject var teamsManager: TeamsManager
    let onSignOut: () -> Void
//    private let isOwner = true
    
    @FocusState private var focus: SettingsFocus?
    @EnvironmentObject var userAuth: UserAuthModel
    @EnvironmentObject var server: ServerModel
    
    // Settings
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .fontWeight(.semibold)
                    .font(.title2)
                
                Spacer()
                Button(action: exit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                }
            }
            .foregroundColor(.white)
            .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                ScrollViewReader { proxy in
                    VStack {
                        
                        // Team name
                        TeamNameTextField(
                            isOwner: teamsManager.owner()?.email == userAuth.email,
                            name: $name,
                            focus: _focus
                        ) { newName in
                            if newName != teamsManager.selectedTeam?.name ?? "" {
                                server.renameTeam(to: newName)
//                                teamsManager.rename(to: newName)
                                name = newName
                            }
                        }
                        .id("start")
                        .onChange(of: focus == .name) { inFocus in
                            if !inFocus { return }
                            proxy.scrollTo("start")
                        }
                        
                        Divider()
                            .frame(height: 1)
                            .background(.white.opacity(0.8))
                        
                        // Members
                        TeamMembersView(
                            isOwner: teamsManager.owner()?.email == userAuth.email,
                            expandable: true,
                            focus: _focus,
                            teamsManager: teamsManager,
                            add: { member in server.addMember(member: member) },
                            remove: { email in server.removeMember(email: email)},
                            setCapturer: { email in server.setCapturer(email: email)}
                        ) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(Animation.linear(duration: 0.2)) {
                                    proxy.scrollTo("end", anchor: .center)
                                }
                            }
                        }
                        
//                        Divider()
//                            .frame(height: 1)
//                            .background(.white.opacity(0.8))

                        // Color - if owner
                        
                        // Captures per play
//                        CapturesPerPlayTextField(
//                            isOwner: isOwner,
//                            capturesPerPlay: $capturesPerPlay,
//                            focus: _focus
//                        )
//                        .onChange(of: focus == .capturesPerPlay) { inFocus in
//                            if !inFocus { return }
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                                withAnimation(Animation.linear(duration: 0.2)) {
//                                    proxy.scrollTo("end")
//                                }
//                            }
//                        }
                        
                        Divider()
                            .frame(height: 1)
                            .background(.white.opacity(0.8))
                        
                        // Sign out
                        Button(action: {
                            exit()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                userAuth.signOut()
                                onSignOut()                                
                            }
                        }) {
                            Text("Sign out")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding(8)
                                .id("end")
                            
                        }
                        .background(AppColors.contrast)
                        .cornerRadius(8)
                    }
                }
                
            }
            // Other rules cooper wants
            Spacer()
            
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if focus != nil {
                focus = nil
            }
        }
        .padding(16)
        .background(AppColors.primary)
        .onAppear {
            guard let team = teamsManager.selectedTeam else { exit(); return }
            name = team.name
        }
    }
    
    enum SettingsFocus: Hashable {
        case name
        case addMember
        case capturesPerPlay
    }
}

struct TeamNameTextField: View {
    let isOwner: Bool
    @Binding var name: String
    @FocusState var focus: SettingsView.SettingsFocus?
    let onSave: (String) -> Void
    
    var body: some View {
        HStack {
            if focus == .name {
                Button(action: {
                    focus = nil
                    onSave(name)
                }) {
                    Text("Save".uppercased())
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 18)
                        .fontWeight(.bold)
                        .background(name.isEmpty ? AppColors.contrast : AppColors.secondary)
                        .cornerRadius(6)
                    
                }
                .disabled(name.isEmpty)
            } else {
                Text("Team Name".uppercased())
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            TextField("The name of your team", text: $name)
                .submitLabel(.done)
                .multilineTextAlignment(.trailing)
                .disabled(!isOwner)
                .ignoresSafeArea(.keyboard)
                .focused($focus, equals: .name)
                .frame(maxWidth: name.isEmpty ? .infinity : 12*Double(name.count))
                .onSubmit {
                    onSave(name)
                }
        }
        .fontWeight(.semibold)
        .padding(.horizontal, 12)
        .padding(.vertical, focus == .name ? 8 : 12)
//        .overlay {
//            Color.black.opacity(0)
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    if focus != nil {
//                        focus = nil
//                    } else {
//                        focus = .name
//                    }
//                }
//        }
    }
}

struct TeamMembersView: View {
    let isOwner: Bool
    let expandable: Bool
    @FocusState var focus: SettingsView.SettingsFocus?
    @ObservedObject var teamsManager: TeamsManager
    let add: (Team.Member) -> Void
    let remove: (String) -> Void
    let setCapturer: (String) -> Void
    
    let scrollToAdd: () -> Void
    @State private var expanded = false
    
    var body: some View {
        VStack {
            if expandable {
                Button(action: {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        expanded = !expanded
                    }
                    
                }) {
                    HStack {
                        Text("Members (\(teamsManager.selectedTeam?.members.count ?? 0)/5)".uppercased())
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .rotationEffect(Angle(degrees: expanded ? -90 : 0))
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(12)
                }
                .onChange(of: focus == nil) { isFocused in
                    if !isFocused && focus != .addMember {
                        withAnimation(Animation.linear(duration: 0.1)) {
                            expanded = false
                        }
                    }
                }
            } else {
                HStack {
                    Text("Members (\(teamsManager.selectedTeam?.members.count ?? 0)/5)".uppercased())
                    Spacer()
                }
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
                .padding(12)
            }
            
            if (expanded || !expandable) && teamsManager.selectedTeam != nil {
                Group {
                    if isOwner {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20, weight: .semibold, design: .default))
                                .padding(4)
                            Text("Tap a user to make them the team capturer")
                            Spacer()
                        }
                        .foregroundColor(.gray)                        
                    }
                    
                    ForEach(teamsManager.selectedTeam!.members) { member in
                        MemberView(member: member, isOwner: isOwner, owner: teamsManager.owner()?.email ?? "", setCapturer: {
                            setCapturer(member.email)
                        }) {
                            remove(member.email)
                        }
                        
                        if teamsManager.selectedTeam?.members.count ?? 0 < 5 && isOwner {
//                        if (members.count < 5 || member.name != members.last!.name) && isOwner {
                            Divider()
                                .frame(height: 1)
                                .background(.white.opacity(0.8))
                        }
                    }
                    
                    if teamsManager.selectedTeam!.members.count < 5 && isOwner {
                        AddMemberView(focus: _focus, scroll: scrollToAdd) { email in
                            add(Team.Member(name: email, email: email.lowercased()))
//                            teamsManager.selectedTeam!.members.append(Team.Member(name: "Unkown"))
                        }
                    }
                }
                .padding(.horizontal, 16)

            }
        }
    }
    
    struct MemberView: View {
        let member: Team.Member
        let isOwner: Bool
        let owner: String
        let setCapturer: () -> Void
        let remove: () -> Void
        
        @State private var inRemoveMember = false
        @State private var inSetCapturer = false
        
        var body: some View {
            Button(action: {
                if isOwner && !member.isCapturer {
                    inSetCapturer = true
                }
            }) {
                HStack {
                    Text(member.name())
                        .fontWeight(.semibold)
                    Spacer()
                    
                    Text(member.email)
                    
                    // Capturing
                    if member.isCapturer {
                        Image(systemName: member.isCapturing ? "camera.fill" : "camera")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(member.isCapturing ? .white : .gray)
                            .padding(4)
                    }

                    // Viewing
                    if member.isViewing {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(4)
                    }
                    
                    if owner != member.email && isOwner {
                        Button(action: {
                            if isOwner {
                                inRemoveMember = true
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 22, weight: .semibold, design: .default))
                                .foregroundColor(isOwner ? .red : .gray)
                                .padding(4)
                        }
                    }
                }
                .foregroundColor(.white)
            }
            .alert("Remove \(member.name())?", isPresented: $inRemoveMember, actions: {
                Button("Cancel", role: .cancel) {
                    
                }
                Button("Remove", role: .destructive) {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        remove()
                    }
                }
            })
            .alert("Make \(member.name()) the team capturer?", isPresented: $inSetCapturer, actions: {
                Button("Cancel", role: .cancel) {
                    
                }
                Button("Confirm") {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        setCapturer()
                    }
                }
            })
        }
    }
    
    struct AddMemberView: View {
        @FocusState var focus: SettingsView.SettingsFocus?
        let scroll: () -> Void
        let add: (String) -> Void
        @State private var email: String = ""
        
        var body: some View {
            HStack {
                Button(action: {
                    withAnimation(Animation.linear(duration: 0.2)) {
                        add(email)
                    }
                    email = ""
                    focus = nil
                }) {
                    Text("Add".uppercased())
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 18)
                        .fontWeight(.bold)
                        .background(!isValidEmail(email) ? AppColors.contrast : AppColors.secondary)
                        .cornerRadius(6)
                    
                }
                .disabled(!isValidEmail(email))
                
                Spacer()
                TextField("New members email address", text: $email)
                    .submitLabel(.done)
                    .keyboardType(.emailAddress)
                    .multilineTextAlignment(.trailing)
                    .focused($focus, equals: .addMember)
                
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if focus == nil {
                    focus = .addMember
                } else {
                    focus = nil
                }
            }
            .onChange(of: focus == .addMember) { focused in
                if !focused { return }
                scroll()
            }
        }
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func isValidText(_ text: String) -> Bool {
    return text.allSatisfy { x in x.isASCII } && !text.allSatisfy { x in x.isWhitespace }
}
