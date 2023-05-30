//
//  TeamsManager.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-03-03.
//

import Foundation
import SwiftUI

class TeamsManager: ObservableObject {
    @Published var selectedTeam: Team? = nil
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var hasLoaded = false
    
    private var selectedTeamIdx: Int? = nil
    
    static func initial() -> TeamsManager {
        let instance = TeamsManager()
        
        if instance.teams.count == 1 {
            instance.select(instance.teams[0].id)
        }
        
        return instance
    }
    
    func select(_ teamId: String?) {
        selectedTeamIdx = teams.firstIndex { team in team.id == teamId }
        updateSelectedTeam()
    }
    
    func rename(to: String) {
        guard let idx = selectedTeamIdx else { return }
        DispatchQueue.main.async {
            self.teams[idx].name = to.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        updateSelectedTeam()
    }
    
    func setId(to: String) {
        guard let idx = selectedTeamIdx else { return }
        teams[idx].id = to
        
        updateSelectedTeam()
    }
    
    func create(name: String, owner: Team.Member) {
        let newTeam = Team(name, owner, members: [owner])
        teams.append(newTeam)
        self.select(newTeam.id)
    }
    
    func destroy(_ teamId: String) {
        select(nil)
        guard let idx = teams.firstIndex(where: { x in x.id == teamId }) else { return }
        teams.remove(at: idx)
    }
    
    func setCapturer(to: String) {
        guard let idx = selectedTeamIdx else { return }
        
        let memberIdx = teams[idx].members.firstIndex { member in member.email == to }
        guard let memberIdx = memberIdx else { return }
        
        DispatchQueue.main.async {
            self.teams[idx].members.enumerated().forEach { index, member in self.teams[idx].members[index].isCapturer = false }
            self.teams[idx].members[memberIdx].isCapturer = true
        }
        
        updateSelectedTeam()
    }
    
    func setCapturing(to: Bool) {
        guard let idx = selectedTeamIdx else { return }
        
        let memberIdx = teams[idx].members.firstIndex { member in member.isCapturer }
        guard let memberIdx = memberIdx else { return }
        
        DispatchQueue.main.async {
            self.teams[idx].members[memberIdx].isCapturing = to
        }
        
        updateSelectedTeam()
    }
    
    func setViewing(email: String, to: Bool) {
        guard let idx = selectedTeamIdx else { return }
        
        let memberIdx = teams[idx].members.firstIndex { member in member.email == email }
        guard let memberIdx = memberIdx else { return }
        
        DispatchQueue.main.async {
            self.teams[idx].members[memberIdx].isViewing = to
        }
        
        updateSelectedTeam()
    }
    
    func add(member: Team.Member) {
        guard let idx = selectedTeamIdx else { return }
        teams[idx].members.append(member)
        updateSelectedTeam()
    }
    
    func remove(email: String) {
        guard let idx = selectedTeamIdx else { return }
        
        let memberIdx = teams[idx].members.firstIndex { member in member.email == email }
        guard let memberIdx = memberIdx else { return }
        
        // Make owner capturer if necessary
        if teams[idx].members[memberIdx].isCapturer {
            teams[idx].members[teams[idx].members.firstIndex { x in x.email == teams[idx].owner } ?? 0].isCapturer = true
        }
        teams[idx].members.remove(at: memberIdx)
        updateSelectedTeam()
    }
    
    func owner() -> Team.Member? {
        guard let idx = selectedTeamIdx else { return nil }
        let memberIdx = teams[idx].members.firstIndex { member in member.email == teams[idx].owner }
        guard let memberIdx = memberIdx else { return nil }
        return teams[idx].members[memberIdx]
    }
    
    func capturing() -> Team.Member? {
        guard let idx = selectedTeamIdx else { return nil }
        let memberIdx = teams[idx].members.firstIndex { member in member.isCapturing }
        guard let memberIdx = memberIdx else { return nil }
        return teams[idx].members[memberIdx]
    }
    
    func capturer() -> Team.Member? {
        guard let idx = selectedTeamIdx else { return nil }
        let memberIdx = teams[idx].members.firstIndex { member in member.isCapturer }
        guard let memberIdx = memberIdx else { return nil }
        return teams[idx].members[memberIdx]
    }
    
    func startGame(withName name: String) {
        DispatchQueue.main.async {
            guard let idx = self.selectedTeamIdx else { return }
            self.teams[idx].game = Game(name: name)
            self.updateSelectedTeam()                
        }
    }
    
    func endGame() {
        guard let idx = selectedTeamIdx else { return }
        DispatchQueue.main.async {
            self.teams[idx].game = nil            
        }
        updateSelectedTeam()
    }
    
    func loadTeams(_ teams: [Team]) {
        DispatchQueue.main.async {
            withAnimation(Animation.linear(duration: 0.2)) {
                self.hasLoaded = true
                self.teams = teams                
            }
        }
    }
    
    func unloadTeams() {
        DispatchQueue.main.async {
            self.hasLoaded = false
            self.teams = []
        }
    }
    
    private func updateSelectedTeam() {
        DispatchQueue.main.async {
            self.selectedTeam = self.selectedTeamIdx != nil ? self.teams[self.selectedTeamIdx!] : nil            
        }
    }
    
}
