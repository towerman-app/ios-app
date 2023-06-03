//
//  PhotoCache.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-05-07.
//

import Foundation
import SwiftUI

class PhotoCache: ObservableObject {
    @Published var photos: Array<Series> = [];
    @Published var filtered: Array<Series> = [];
    @Published var names: Array<String> = [];
//    @Published var photos: Array<PlayPhoto> = [];
    
    private var filters = Filters()
    
    func clear() {
        self.names = [];
        self.photos = [];
    }
    
    func filter(
        odk: Array<String>? = nil,
        quarter: Array<String>? = nil,
        down: Array<String>? = nil,
        gain: ClosedRange<Int>? = nil,
        distance: ClosedRange<Int>? = nil,
        isFlagged: Bool? = nil
    ) {
        photos.sort { s1, s2 in
            s1.number < s2.number
        }
        filters = filters.update(odk: odk, quarter: quarter, down: down, gain: gain, distance: distance, isFlagged: isFlagged)
        
        if filters.showAll() {
//            withAnimation(Animation.linear(duration: 0.2)) {
                filtered = photos
//            }
            return
        }
        
        // Let the fuckery begin
        var filteredPlays: Array<Series> = []
        
        photos.forEach { series in
            let plays = series.plays.filter { play in
                filters.match(play.play)
            }
            
            if !plays.isEmpty {
//                print(plays)
                filteredPlays.append(Series(number: series.number, plays: plays))
            }
        }
        
//        withAnimation(Animation.linear(duration: 0.2)) {
            filtered = filteredPlays            
//        }
    }
    
    func add(_ photo: PlayPhoto) {
        if self.names.contains(where: { x in x == "\(photo.play.name())#\(photo.idx)" }) {
            print("photo already added")
            return
        }
        print("Adding photo...")
        DispatchQueue.main.async {
            self.names.append("\(photo.play.name())#\(photo.idx)")
        }
        
        let seriesIdx = photos.firstIndex { x in x.number == photo.play.series }
        guard let seriesIdx = seriesIdx else {
            let series = Series(number: photo.play.series, plays: [SeriesPlay(play: photo.play, photos: [photo.pic])])
            
            DispatchQueue.main.async {
                self.photos.append(series)
                withAnimation(Animation.linear(duration: 0.2)) {
                    self.filter()
                }
            }
            return
        }
        let playIdx = photos[seriesIdx].plays.firstIndex { x in x.play == photo.play }
        guard let playIdx = playIdx else {
            let play = SeriesPlay(play: photo.play, photos: [photo.pic])
            
            DispatchQueue.main.async {
                self.photos[seriesIdx].plays.append(play)
                
                withAnimation(Animation.linear(duration: 0.2)) {
                    self.filter()
                }
            }
            return
        }
        DispatchQueue.main.async {
            self.photos[seriesIdx].plays[playIdx].photos.append(photo.pic)
            
            withAnimation(Animation.linear(duration: 0.2)) {
                self.filter()                
            }
        }
    }
}

struct Series: Identifiable {
    var id = UUID()
    
    let number: Int
    var plays: Array<SeriesPlay>
}

struct SeriesPlay: Identifiable {
    var id = UUID()
    
    let play: PlayData
    var photos: Array<UIImage>
}

struct Filters {
    let odk: Array<String>
    let quarter: Array<String>
    let down: Array<String>
    let gain: ClosedRange<Int>
    let distance: ClosedRange<Int>
    let isFlagged: Bool
    
    init(odk: Array<String>? = nil, quarter: Array<String>? = nil, down: Array<String>? = nil, gain: ClosedRange<Int>? = nil, distance: ClosedRange<Int>? = nil, isFlagged: Bool? = nil) {
        self.odk = odk ?? []
        self.quarter = quarter ?? []
        self.down = down ?? []
        self.gain = gain ?? ClosedRange(uncheckedBounds: (-30, 99))
        self.distance = distance ?? ClosedRange(uncheckedBounds: (-1, 1))
        self.isFlagged = isFlagged ?? false
    }
    
    func update(odk: Array<String>? = nil, quarter: Array<String>? = nil, down: Array<String>? = nil, gain: ClosedRange<Int>? = nil, distance: ClosedRange<Int>? = nil, isFlagged: Bool? = nil) -> Filters {
        return Filters(
            odk: odk ?? self.odk,
            quarter: quarter ?? self.quarter,
            down: down ?? self.down,
            gain: gain ?? self.gain,
            distance: distance ?? self.distance,
            isFlagged: isFlagged ?? self.isFlagged
        )
    }
    
    func showAll() -> Bool {
        if !odk.isEmpty && odk.count != 3 { return false }
        if !quarter.isEmpty && quarter.count != 4 { return false }
        if !down.isEmpty && down.count != 3 { return false }

        if gain.lowerBound != -30 || gain.upperBound != 99 { return false }
        if distance.lowerBound != -1 || distance.upperBound != 1 { return false }
        
        if isFlagged { return false }
        
        return true
    }
    
    func match(_ play: PlayData) -> Bool {
        if !odk.isEmpty && !odk.contains(play.odk) { return false }
        if !quarter.isEmpty && !quarter.contains(String(play.quarter)) { return false }
        if !down.isEmpty && down.count != 3 && !down.contains((play.down ?? 0).fancy()) { return false }
        
        if play.gain < gain.lowerBound || play.gain > gain.upperBound { return false }
        
        // MARK: Probably need to change this
        print("remember to change PhotoCache:Filter:match")
//        if play.distance < distance.lowerBound || play.distance > distance.upperBound { return false }
        
        if isFlagged && !play.flagged { return false }
        
        return true
    }
}
