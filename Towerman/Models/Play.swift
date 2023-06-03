//
//  Play.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import Foundation

struct Play {
    var quarter: Int
    var odk: String
    var down: Int
    var distance: Int
    var startLine: Int
    var endLine: Int
    var series: Int
    var flagged: Bool
    
    func toPlayData() -> PlayData {
        return PlayData(quarter: quarter, odk: odk, down: down == -1 ? nil : down, distance: distance, startLine: startLine, endLine: endLine, gain: gain(), series: series, flagged: flagged, id: 0)
    }
    
    func gain() -> Int {
        if (startLine < 0 && endLine < 0) || (startLine >= 0 && endLine >= 0) {
            return startLine - endLine
        }
        if startLine < 0 {
            return startLine - endLine + 110
        }
        
        return startLine - endLine - 110
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
        
        return Play (
            quarter: quarter ?? self.quarter,
            odk: odk ?? self.odk,
            down: down ?? self.down,
            distance: distance ?? self.distance,
            startLine: startLine ?? self.startLine,
            endLine: endLine ?? self.endLine,
            series: series ?? self.series,
            flagged: flagged ?? self.flagged
        )
        // MARK: Save the state to smth so if app is closed we can fix it later
    }
}
