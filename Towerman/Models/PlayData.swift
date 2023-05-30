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
    let series: Int
    let flagged: Bool
    
    func name() -> String {
        return "Q\(quarter)_\(odk)_D\(down != nil ? String(down!) : "-")_\(startLine)~\(endLine)_S\(series)\(flagged ? "FLAGGED" : "")"
    }
    
    
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
