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
    @Published var names: Array<String> = [];
//    @Published var photos: Array<PlayPhoto> = [];
    
    func clear() {
        self.names = [];
        self.photos = [];
    }
    
    func add(_ photo: PlayPhoto) {
        print("Adding photo...")
        DispatchQueue.main.async {
            self.names.append("\(photo.play.name())#\(photo.idx)")
        }
        
        let seriesIdx = photos.firstIndex { x in x.number == photo.play.series }
        guard let seriesIdx = seriesIdx else {
            let series = Series(number: photo.play.series, plays: [SeriesPlay(play: photo.play, photos: [photo.pic])])
            
            DispatchQueue.main.async {
                self.photos.append(series)
            }
            return
        }
        let playIdx = photos[seriesIdx].plays.firstIndex { x in x.play == photo.play }
        guard let playIdx = playIdx else {
            let play = SeriesPlay(play: photo.play, photos: [photo.pic])
            
            DispatchQueue.main.async {
                self.photos[seriesIdx].plays.append(play)
            }
            return
        }
        DispatchQueue.main.async {
            self.photos[seriesIdx].plays[playIdx].photos.append(photo.pic)
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
