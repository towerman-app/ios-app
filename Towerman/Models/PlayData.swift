//
//  PlayData.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-11.
//

import Foundation
import UIKit
import SwiftUI

struct PlayData: Codable, Equatable {
    let quarter: Int
    let odk: String
    let down: Int?
    let distance: Int
    let startLine: Int
    let endLine: Int
    let gain: Int
    let series: Int
    let flagged: Bool
    let id: Int
    
    func name() -> String {
        // Q1_S1_K_D1_0~0_G-50FLAGGED
        return "Q\(quarter)_S\(odk == "K" ? "-" : String(series))_\(odk)_D\(down != nil ? String(down!) + "&\(distance)" : "-")_\(startLine)~\(endLine)_G\(gain)_\(flagged ? "FLAGGED" : "")"
//        return "Q\(quarter)_\(odk)_D\(down != nil ? String(down!) : "-")_\(startLine)~\(endLine)_S\(series)\(flagged ? "FLAGGED" : "")"
    }
    
//    func gain() -> Int {
//        if (startLine < 0 && endLine < 0) || (startLine >= 0 && endLine >= 0) {
//            return startLine - endLine
//        }
//        if startLine < 0 {
//            return startLine - endLine + 110
//        }
//
//        return startLine - endLine - 110
//    }
    
    
    struct PlayPhoto: Codable {
        let data: Data
        
        static func dummy() -> PlayPhoto {
            if let asset = NSDataAsset(name: "example-image") {
                let data = asset.data
                return PlayPhoto(data: data)
            }
            return PlayPhoto(data: Data())
        }
        
        func toImage() -> UIImage {
#if canImport(UIKit)
            let img: UIImage = UIImage(data: self.data) ?? UIImage()
            return img
#elseif canImport(AppKit)
            let img: NSImage = NSImage(data: self.data) ?? NSImage()
            return Image(nsImage: img)
#else
            return Image(systemImage: "xmark.octagon.fill")
#endif
        }
    }
}
