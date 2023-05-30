//
//  PhotosPreviewView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import SwiftUI

struct PhotosPreviewView: View {
    @Binding var photos: [PlayData.PlayPhoto]
    
    @Binding var expandedPhotoIdx: Int?
    @State private var inDeletePhoto = false
    @State private var deleteHash: Int = 0
    
    @State var enterCapture: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView(showsIndicators: false) {
                ForEach(Array(photos.enumerated()), id: \.offset) { idx, photo in
                    
                    Button(action: {
                        withAnimation(Animation.linear(duration: 0.1)) {
                            expandedPhotoIdx = idx
                        }
                    }) {
                        Image(uiImage: photo.toImage())
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(4)
                            .shadow(radius: 4)
                            .padding(8)
                    }
                    .overlay {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    deleteHash = photo.data.hashValue
                                    inDeletePhoto = true
                                }) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 22, weight: .semibold, design: .default))
                                        .foregroundColor(.gray)
                                        .overlay {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 14, weight: .heavy, design: .default))
                                                .foregroundColor(.black)
                                        }
                                }
                            }
                            Spacer()
                        }
                    }
                    
                }
                
                Button(action: enterCapture) {
                    HStack(spacing: 10) {
                        Spacer()
                        Text("CAPTURE")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Image(systemName: "camera")
                            .resizable()
                            .frame(width: 22, height: 18)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppColors.contrast)
                    .cornerRadius(8)
                }
                .shadow(radius: 4)
                .padding(4)
                
            }
        }
        .alert("Delete photo?", isPresented: $inDeletePhoto, actions: {
            Button("Cancel", role: .cancel) {
                
            }
            Button("Delete", role: .destructive) {
                withAnimation(Animation.linear(duration: 0.1)) {
                    photos.removeAll(where: { x in x.data.hashValue == deleteHash} )
                    
                }
            }
        })
    }
}

