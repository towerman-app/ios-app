//
//  ExpandedPhotoView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import SwiftUI

struct ExpandedPhotoView: View {
    @Binding var photos: [PlayData.PlayPhoto]
    @Binding var expandedPhotoIdx: Int?
    
    let play: Play
    @State private var cache: [UIImage] = []
    @State private var inDeletePhoto = false
    @State private var photoCount: Int = 0
    
    var body: some View {
        ZStack {
            
            if let idx = expandedPhotoIdx {
                Color.black.edgesIgnoringSafeArea(.all)
                    .zIndex(-1)
                    .onAppear {
                        cache = []
                        photos.forEach { photo in
                            cache.append(photo.toImage())
                        }
                        photoCount = photos.count
                    }
                
                HStack {
                    Button(action: {
                        withAnimation(Animation.linear(duration: 0.25)) {
                            if idx == 0 {
                                expandedPhotoIdx! = photos.count-1
                            } else {
                                expandedPhotoIdx! = idx-1
                            }
                        }
                        
                    }) {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .fontWeight(.semibold)
                            .foregroundColor(photos.count == 1 ? .gray : .white)
                            .padding(16)
                            .background(AppColors.contrast)
                            .cornerRadius(8)
                    }
                    .zIndex(1)

                    if cache.count-1 >= idx {
                        Image(uiImage: cache[idx])
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(4)
                            .padding(12)
                            .overlay {
                                VStack {
                                    // Add some space
//                                    let play = tagging.tagging
//                                    let play = Play(quarter: 1, odk: "K", down: 1, distance: 0, startLine: 0, endLine: 0, series: 1, flagged: false)
                                    let keys: [(String, String)] = [
                                        ("Q", String(play.quarter)),
                                        ("ODK", play.odk),
                                        ("DN", play.down == -1 ? "" : String(play.down)),
                                        ("DST", String(play.distance)),
                                        ("ST", String(play.startLine)),
                                        ("END", String(play.endLine)),
                                        ("S", String(play.series))
                                    ]
                                    HStack {
                                        ForEach(0..<keys.count, id: \.self) { i in
                                            if keys[i].1 != "" {
                                                Group {
                                                    if i != 0 {
                                                        Spacer()
                                                        Text("|")
                                                        Spacer()
                                                    }
                                                    Text("\(keys[i].0): \(keys[i].1)")
                                                }
                                            }
                                            
                                        }
                                        
                                        if play.flagged {
                                            Spacer()
                                            Text("|")
                                            Spacer()
                                            Image(systemName: "flag.fill")
                                                .font(.system(size: 18, weight: .semibold, design: .default))
                                                .foregroundColor(.red)
//                                            Text("FLAGGED")
                                        }
                                    }
                                    .fontWeight(.bold)
                                    .padding(8)
                                    .background(.black.opacity(0.5))
                                    .padding(12)
                                    
                                    Spacer()
                                }
                            }
                    } else {
                        Rectangle()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(4)
                            .padding(12)
                    }
                    
                    Button(action: {
                        withAnimation(Animation.linear(duration: 0.25)) {
                            if idx == photos.count-1 {
                                expandedPhotoIdx! = 0
                            } else {
                                expandedPhotoIdx! = idx+1
                            }
                        }
                        
                    }) {
                        Image(systemName: "arrow.right")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .fontWeight(.semibold)
                            .foregroundColor(photos.count == 1 ? .gray : .white)
                            .padding(16)
                            .background(AppColors.contrast)
                            .cornerRadius(8)
                    }
                    .zIndex(1)
                }
                .transition(.move(edge: .bottom))
                
                HStack {
                    Spacer()
                    VStack {
                        Text(String(expandedPhotoIdx! + 1) + "/" + String(photoCount))
                            .fontWeight(.bold)
                            .padding(8)
                            .background(AppColors.contrast)
                            .cornerRadius(8)
                        
                        Spacer()
                        Button(action: {
                            withAnimation(Animation.linear(duration: 0.2)) {
                                inDeletePhoto = true

                            }
                            
                        }) {
                            Image(systemName: "trash")
                                .resizable()
                                .frame(width: 20, height: 24)
                                .foregroundColor(.red)
                                .padding(16)
                                .background(AppColors.contrast)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
                
                
            }
        }
        .alert("Delete photo?", isPresented: $inDeletePhoto, actions: {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Delete", role: .destructive) {
                photos.remove(at: expandedPhotoIdx!)
                cache.remove(at: expandedPhotoIdx!)
                photoCount -= 1

                let initialIdx = expandedPhotoIdx!
                withAnimation(Animation.linear(duration: 0.2)) {
                    if photos.isEmpty {
                        expandedPhotoIdx = nil
                    } else if initialIdx == 0 {
                        expandedPhotoIdx = photos.count-1
                    } else {
                        expandedPhotoIdx = initialIdx - 1
                    }
                }

            }
        })
        .onTapGesture {
            withAnimation(Animation.linear(duration: 0.1)) {
                expandedPhotoIdx = nil
            }
        }
    }
}

