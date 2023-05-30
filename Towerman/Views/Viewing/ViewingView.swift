//
//  ViewingView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-04-28.
//

import SwiftUI

struct ViewingView: View {
    @Binding var screen: AppScreen
    
    @EnvironmentObject var server: ServerModel
    @EnvironmentObject var photoCache: PhotoCache
        
    @State private var inFiltersDrawer = false
    @State private var expandedPlay: SeriesPlay? = nil
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 48) {
                    ForEach(photoCache.photos.reversed()) { series in
                        SeriesRow(series: series, expanded: $expandedPlay)

                    }
                }
                .padding(.vertical, 32)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        server.stopViewing()
                        change($screen, to: .modeSelect)
                        
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                }
                Spacer()
            }
            
            FilterDrawerView(isActive: $inFiltersDrawer)
            if let play = expandedPlay {
                ExpandedPlayView(onExit: { expandedPlay = nil }, play: play)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
    }
}

private struct FilterWidget: View {
    @Binding var isActive: Bool
    var body: some View {
        Button(action: {
            withAnimation(Animation.linear(duration: 0.2)) {
                isActive = !isActive
            }
        }) {
            ZStack {
                Image(systemName: "chevron.right.circle")
                    .rotationEffect(Angle(degrees: isActive ? 0 : 90))
                    .opacity(isActive ? 1 : 0)
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .rotationEffect(Angle(degrees: isActive ? -90 : 0))
                    .opacity(isActive ? 0 : 1)
            }
            .font(.system(size: 28, weight: .semibold, design: .default))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 32)
            .background(AppColors.secondary)
            .cornerRadius(12)
            .shadow(radius: isActive ? 0 : 6)
        
//            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct FilterDrawerView: View {
    @Binding var isActive: Bool
    
    @State private var offset: CGFloat = 0
    var body: some View {
            ZStack {
                
                if isActive {
                    Color.black.opacity(0.5 - (offset / 700.0))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(Animation.linear(duration: 0.2)) {
                                isActive = false
                            }
                        }
                }
                
                HStack {
                    Spacer()
                
                    FilterWidget(isActive: $isActive)
                    .padding(.trailing, 8)
                    
                    if isActive {
                        VStack {
                            QuarterButtons()
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Clear Filters")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding(8)
                                    .background(AppColors.secondary)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 32)
                        .background(AppColors.primary)
                        .cornerRadius(8)
                        .padding(16)
                        .transition(.move(edge: .trailing))
                }
            }
                .offset(x: offset)
                .gesture(DragGesture()
                    .onChanged({ val in
                        offset = max(val.translation.width / 7.0, val.translation.width)
                        
                    }).onEnded({ val in
                        withAnimation(Animation.linear(duration: 0.2)) {
                            offset = 0
                            if val.predictedEndTranslation.width > 100 {
                                isActive = false
                            }
                        }
                        
                    })
                )
        }
    }
    
    private struct QuarterButtons: View {
        @State var selected: String = ""
        var body: some View {
            VStack {
                HStack {
                    QButton(title: "Q1", selected: $selected)
                    QButton(title: "Q2", selected: $selected)
                }
                HStack {
                    QButton(title: "Q3", selected: $selected)
                    QButton(title: "Q4", selected: $selected)
                }
            }
        }
    }
    
    private struct QButton: View {
        let title: String
        @Binding var selected: String
        var body: some View {
            Button(action: {
                selected = (selected == title ? "" : title)
            }) {
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .padding(16)
                    .background(selected == title ? AppColors.secondary : AppColors.contrast)
                    .cornerRadius(8)
                    .shadow(radius: selected == title ? 6 : 2)
            }
        }
    }
}

private struct SeriesRow: View {
    let series: Series
    @Binding var expanded: SeriesPlay?
//    let photos: Array<PlayPhoto>
    var body: some View {
        VStack(alignment: .leading) {
            Text("SERIES \(series.number)")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(series.plays) { play in
                        PlayView(name: "\(play.play.down?.fancy() ?? "-") & ? @ \(play.play.startLine) | \(play.play.odk)", img: play.photos[0]) {
                            expanded = play
                        }
                            .transition(.opacity)
                    }
                }
                .padding(.leading, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct PlayView: View {
    let name: String
    @State var img: UIImage
    let onClick: () -> Void
    @State private var load = false
    var body: some View {
        Button(action: {
            withAnimation(Animation.linear(duration: 0.2)) {
                onClick()
            }
        }) {
            ZStack {
                Rectangle()
                    .foregroundColor(.gray)
                    .opacity(load ? 0 : 1)
                
                if let img = img {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.opacity)
                }
            }
            .frame(height: 150)
            .frame(minWidth: 260)
            .cornerRadius(4)
            .onAppear {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    self.img = PlayData.PlayPhoto.dummy().toImage()
//                }
                withAnimation(Animation.linear(duration: 0.2).delay(0.1)) {
                    load = true
                }
            }
            .onDisappear {
//                self.img = nil
                load = false
            }
            .overlay {
                HStack {
                    VStack {
                        Text(name)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .padding(4)
                            .background(.black.opacity(0.7))
                            .cornerRadius(4)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(PhotoButton())
    }
    
    private struct PhotoButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
//                .shadow(radius: configuration.isPressed ? 8 : 0)
        }
    }
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}

