//
//  Photo.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-05-07.
//

import Foundation
import SwiftUI

struct PlayPhoto: Identifiable {
    let play: PlayData
    let idx: Int
    let pic: UIImage
    
    var id = UUID()
    
    static func parse(name: String, photo: Data) -> PlayPhoto? {
        // Photo
#if canImport(UIKit)
        let img: UIImage = UIImage(data: photo) ?? UIImage()
#elseif canImport(AppKit)
        let nsImg: NSImage = NSImage(data: self.data) ?? NSImage()
        let img = Image(nsImage: nsImg)
#else
//        let img = Image(systemImage: "xmark.octagon.fill")
        return nil
#endif
        
        // Q1, S1, K, D1&10, 0~0, G-50, FLAGGED#1-0
        
        let id = Int(name.components(separatedBy: "-").last!)
        guard let id = id else { return nil }
        
        let idx = Int(name.components(separatedBy: "#").last!.components(separatedBy: "-")[0])
        guard let idx = idx else { return nil }
        
        let flagged = name.contains("FLAGGED")
        let parts = name.components(separatedBy: "_")
        
        let quarter = Int(parts[0].suffix(1))
        guard let quarter = quarter else { return nil }
        
        let series = Int(parts[1].dropFirst())
        guard let series = series else { return nil }
        
        let odk = parts[2]
        let down = (parts[3] == "D-" ? nil : Int(parts[3].components(separatedBy: "&")[0].suffix(1)))
        let distance = down != nil ? Int(parts[3].components(separatedBy: "&")[1]) : 0
        guard let distance = distance else { return nil }
        
        let startLine = Int(parts[4].components(separatedBy: "~")[0])
        guard let startLine = startLine else { return nil }
        
        let endLine = Int(parts[4].components(separatedBy: "~")[1])
        guard let endLine = endLine else { return nil }
        
        let gain = Int(parts[5].dropFirst())
        guard let gain = gain else { return nil }
                
        let play = PlayData(
            quarter: quarter,
            odk: odk,
            down: down,
            distance: distance,
            startLine: startLine,
            endLine: endLine,
            gain: gain,
            series: series,
            flagged: flagged,
            id: id
        )
        
        return PlayPhoto(play: play, idx: idx, pic: img)
    }
}
