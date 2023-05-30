//
//  Upload.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import Foundation

struct Upload: Identifiable {
    var id = UUID()
    let name: String
    let photo: Data
    let play: PlayData
    var done = false
    var error: String? = nil
    
//    func name() -> String {
//        return "\(play.quarter)/\(play.odk)/\(play.down)/\(play.distance)/\(play.startLine)/\(play.endLine)/\(play.series)/\(play.flagged ? "t" : "f")/\(idx)"
//    }
}
