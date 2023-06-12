//
//  TaggingManager.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import Foundation

class TaggingManager: ObservableObject {
    @Published var play: Play
    
    @Published private var userChangedDistance = false
    @Published private var userChangedStartLine = false
    @Published private var userChangedEndLine = false
    
    private var lastOdk = "K"
    
    init(_ play: Play) {
        self.play = play
    }
    
    static func inital() -> TaggingManager {
        return TaggingManager(Play(
            quarter: 1,
            odk: "K",
            down: 0,
            distance: 0,
            startLine: -45,
            endLine: 0,
            series: 0,
            flagged: false)
        )
    }
    
    func nextPlay() {
        // Play automation
        
        // **Multiple kicks after touchdown
        
        play.flagged = false
        userChangedDistance = false
        userChangedStartLine = false
        userChangedEndLine = false
        
        // End
        if play.endLine == 0 && play.odk != "K" {
            play.startLine = 5
            play.odk = "K"
            play.down = 0
            return
        }
        
        let gain = play.gain() * (lastOdk == "O" ? 1 : -1)
        if gain < play.distance {
            if play.down == 3 {
                // Change posession
                play.odk = play.odk == "O" ? "D" : "O"
                play.down = 1
                play.distance = 10
            } else {
                play.down += 1
                play.distance -= gain
            }
        } else {
            play.down = 1
            play.distance = 10
        }
        
        if play.odk == "K" {
            play.odk = lastOdk == "O" ? "D" : lastOdk == "D" ? "O" : "K"
            play.down = 1
            play.distance = 10
            play.endLine *= -1
        }
        lastOdk = play.odk == "K" ? lastOdk : play.odk
        
        play.startLine = play.endLine
        
        if play.startLine > 0 {
            play.distance = min(play.distance, play.startLine)
        }
                
        // Set start to previous end
        // if gain < distance: down += 1, distance -= gain (can be bigger than 10).
            // if down > 3: posession change
        // else down = 1, distance = 10
        
        // Posession change
        
        // After kick, posession changes to opposite. down = 1
    
        
//        self.play = self.play.modify(series: self.play.series + 1)
    }
    
    func modify(
        quarter: Int? = nil,
        odk: String? = nil,
        down: Int? = nil,
        distance: Int? = nil,
        startLine: Int? = nil,
        endLine: Int? = nil,
        series: Int? = nil,
        flagged: Bool? = nil
    ) -> Play {
        // MARK: Add fancy logic here
        
        play.series = max(series ?? play.series, 0)
        
        if let distance = distance {
            play.distance = distance
            self.userChangedDistance = true
        }
        
        if let startLine = startLine {
            play.startLine = startLine
            self.userChangedStartLine = true
        }
        
        if let endLine = endLine {
            play.endLine = endLine
            self.userChangedEndLine = true
        }
        
        return play
        // MARK: Save the state to smth so if app is closed we can fix it later
    }
}
