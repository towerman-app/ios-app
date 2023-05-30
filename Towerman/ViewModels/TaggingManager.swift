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
    
    init(_ play: Play) {
        self.play = play
    }
    
    static func inital() -> TaggingManager {
        return TaggingManager(Play(
            quarter: 1,
            odk: "K",
            down: 1,
            distance: 0,
            startLine: 0,
            endLine: 0,
            series: 1,
            flagged: false)
        )
    }
    
    func nextPlay() {
        userChangedDistance = false
        userChangedStartLine = false
        userChangedEndLine = false
        
        self.play = self.play.modify(series: self.play.series + 1)
    }
    
    func modify(
        distance: Int? = nil,
        startLine: Int? = nil,
        endLine: Int? = nil,
        series: Int? = nil
    ) {
        // MARK: Add fancy logic here
        
        play.series = series ?? play.series
        
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
        
        // MARK: Save the state to smth so if app is closed we can fix it later
    }
}
