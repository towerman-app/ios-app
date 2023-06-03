//
//  ViewingView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-04-28.
//

import SwiftUI
import RangeUISlider

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
                    ForEach(photoCache.filtered.reversed()) { series in
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
    
    @State private var odk: Array<String> = []
    @State private var quarter: Array<String> = []
    @State private var down: Array<String> = []
    @State private var isFlagged = false
    
    @State private var gain = ClosedRange(uncheckedBounds: (-30, 99))
    @State private var distance = ClosedRange(uncheckedBounds: (-1, 1))
    
    @EnvironmentObject var photoCache: PhotoCache
        
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
                        VStack(spacing: 0) {
                            
                            Group {
                                FilterButtons(title: "ODK", buttons: ["O", "D", "K"], selected: $odk)
                                    .onChange(of: odk) { newValue in
                                        photoCache.filter(odk: newValue)
                                    }
                                
//                                Spacer()
                                
                                FilterButtons(title: "Quarter", buttons: ["1", "2", "3", "4"], selected: $quarter)
                                    .onChange(of: quarter) { newValue in
                                        photoCache.filter(quarter: newValue)
                                    }
                                
//                                Spacer()
                                
                                FilterButtons(title: "Down", buttons: ["1st", "2nd", "3rd"], selected: $down)
                                    .onChange(of: down) { newValue in
                                        photoCache.filter(down: newValue)
                                    }
                                
//                                Spacer()
                                
                                SlideRange(title: "Gain", value: $gain, range: ClosedRange(uncheckedBounds: (-30, 99)))
                                    .onChange(of: gain) { newValue in
                                        photoCache.filter(gain: newValue)
                                    }
                                
//                                Spacer()
                                
                                SlideRange(title: "Distance", value: $distance, range: ClosedRange(uncheckedBounds: (-1, 1)))
                                    .onChange(of: distance) { newValue in
                                        photoCache.filter(distance: newValue)
                                    }
                                
                            }
                            
//                            Spacer()
                            
                            if UIDevice.isIPad {
                                FlagButton(selected: $isFlagged, full: true)
                                    .onChange(of: isFlagged) { newValue in
                                        photoCache.filter(isFlagged: newValue)
                                    }
                            }
                            
                            Spacer()
                            
                            HStack {
                                if !UIDevice.isIPad {
                                    FlagButton(selected: $isFlagged, full: false)
                                        .onChange(of: isFlagged) { newValue in
                                            photoCache.filter(isFlagged: newValue)
                                        }
                                }

                                Button(action: {
                                    withAnimation(Animation.linear(duration: 0.2)) {
                                        odk = []
                                        quarter = []
                                        down = []
                                        isFlagged = false
                                        gain = ClosedRange(uncheckedBounds: (-30, 99))
                                        distance = ClosedRange(uncheckedBounds: (-1, 1))
                                    }
                                    photoCache.filter()
                                }) {
                                    Text("Clear Filters".uppercased())
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                        .padding(12)
                                        .background(AppColors.secondary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxWidth: UIScreen.screenWidth / 3, maxHeight: .infinity)
                        .padding(.vertical, 8)
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
    
    private struct SlideRange: View {
        let title: String
        @Binding var value: ClosedRange<Int>
        let range: ClosedRange<Int>
        
        @State var lower: CGFloat = 0
        @State var upper: CGFloat = 0
        
        var body: some View {
            VStack {
                Text(title.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                    .padding(.bottom, 4)
                
                
                RangeSliderView(value: $value, bounds: range)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, UIDevice.isIPad ? 32 : 0)

        }
    }
    
    private struct RangeSliderView: View {
        @Binding var value: ClosedRange<Int>
        let bounds: ClosedRange<Int>
        
        @State private var viewSize = CGSize(width: 0, height: 0)
        
        @State private var leftX: CGFloat = 11
        
        var body: some View {
            let pixelsPerStep = (viewSize.width - 22) / CGFloat(bounds.count - 1)
            let offset = -bounds.lowerBound
            ZStack {
                
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            viewSize = geo.size
                        }
                }
                
                // Line
                Rectangle()
                    .foregroundColor(AppColors.contrast)
                    .frame(width: viewSize.width, height: 6)
                    .cornerRadius(4)
                    .overlay {
                        // Left
                        slider(
                            bounds: bounds,
                            pixelsPerStep: pixelsPerStep,
                            offset: offset,
                            viewMid: viewSize.height / 2,
                            value: $value,
                            isLower: true
                        )
                        
                        // Right
                        slider(
                            bounds: bounds,
                            pixelsPerStep: pixelsPerStep,
                            offset: offset,
                            viewMid: viewSize.height / 2,
                            value: $value,
                            isLower: false
                        )
                    }

            }
            .frame(maxHeight: 32)

        }
        
        private struct slider: View {
            let bounds: ClosedRange<Int>
            let pixelsPerStep: CGFloat
            let offset: Int
            let viewMid: CGFloat
            @Binding var value: ClosedRange<Int>
            let isLower: Bool
            @State private var sliderX: CGFloat = 11
            @State private var recentMove = false
            @State private var hideNow = false
            
            
            var body: some View {
                if hideNow {
                    Color.clear
                } else {
                    Circle()
                        .foregroundColor(isLower ? Color(red: 0.5, green: 0.1, blue: 0.15) : Color(red: 0.7, green: 0.15, blue: 0.25))
                        .frame(width: 22, height: 22)
                        .position(x: sliderX, y: 3)
                        .highPriorityGesture(DragGesture()
                            .onChanged({ drag in
                                var location = Int(round((drag.location.x - 11) / pixelsPerStep)) - offset
                                location = max(isLower ? bounds.lowerBound : value.lowerBound + 1, min(isLower ? value.upperBound - 1 : bounds.upperBound, location))
                                
                                value = isLower ? location...value.upperBound : value.lowerBound...location
                                sliderX = CGFloat((isLower ? value.lowerBound : value.upperBound) + offset) * pixelsPerStep + 11
                                
                                if !recentMove {
                                    withAnimation(Animation.linear(duration: 0.2)) {
                                        recentMove = true
                                    }
                                    
                                    withAnimation(Animation.linear(duration: 0.2).delay(1)) {
                                        recentMove = false
                                    }
                                }
                            })
                        )
                        .onChange(of: pixelsPerStep) { pix in
                            sliderX = CGFloat((isLower ? value.lowerBound : value.upperBound) + offset) * pix + 11
                        }
                        .onChange(of: value) { _ in
                            let v = isLower ? value.lowerBound : value.upperBound
                            sliderX = CGFloat(v + offset) * pixelsPerStep + 11
                        }
                        .overlay {
                            let half = (bounds.upperBound + offset) / 2
                            
                            let lowerCase: Bool = isLower && (value.upperBound + offset) > half
                            let upperCase: Bool = !isLower && (value.lowerBound + offset) < half
                            
                            let lowerOut = min(sliderX, (pixelsPerStep * CGFloat(value.upperBound + offset)) - 10)
                            let upperOut = max(sliderX, (pixelsPerStep * CGFloat(value.lowerBound + offset)) + 40)
                            
                            let x = lowerCase ? lowerOut : upperCase ? upperOut : sliderX

                            
                            Text(String(isLower ? value.lowerBound : value.upperBound))
                                .opacity(recentMove ? 1 : 0.5)
                                .scaleEffect(recentMove ? 1.5 : 1)
                                .font(.system(size: 12, weight: .bold))
                                .padding(8)
                                .background(.black.opacity(recentMove ? 1 : 0))
                                .cornerRadius(4)
                                .position(x: x, y: 3 - (UIDevice.isIPad ? (recentMove ? 28 : 18) : (recentMove ? 25 : 0)))
//                                .position(x: x, y: viewMid)
                        }
                        .zIndex((!isLower && value.upperBound == bounds.upperBound) ? 0 : 2)
                }

            }
        }
    }
    
    private struct FlagButton: View {
        @Binding var selected: Bool
        let full: Bool
        var body: some View {
            Button(action: { selected = !selected } ) {
                Image(systemName: selected ? "flag" : "flag.slash")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .padding(12)
                    .frame(maxWidth: full ? .infinity : nil)
                    .foregroundColor(.white)
                    .background(selected ? AppColors.secondary : AppColors.contrast)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(selected ? 0.4 : 0), radius: 8)
                    .padding(.horizontal, 10)
                    .padding(.bottom, UIDevice.isIPad ? 32 : 0)
            }
        }
    }
    
    private struct FilterButtons: View {
        let title: String
        let buttons: Array<String>
        
        @Binding var selected: Array<String>
        
        @State private var fullWidth: CGFloat = 0
        var body: some View {
            VStack(spacing: 0) {
                Text(title.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                
                HStack(spacing: 0) {
                    ForEach(buttons, id: \.self) { button in
                        QButton(title: button, selected: $selected, width: (fullWidth  / CGFloat(buttons.count)) - 8)
                            .padding(4)
                    }
                }
                
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            fullWidth = geo.size.width
                        }
                }
                .frame(height: 0)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, UIDevice.isIPad ? 32 : 0)
        }
    }
    
    private struct QButton: View {
        let title: String
        @Binding var selected: Array<String>
        let width: CGFloat
        let isIcon: Bool = false
        var body: some View {
            
            let isSelected = selected.contains { x in x == title }
            Button(action: {
                if isSelected {
                    selected.removeAll { x in x == title }
                } else {
                    selected.append(title)
                }
            }) {
                Group {
                    if isIcon {
                        Image(systemName: title)
                    } else {
                        Text(title)
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.bold)
                .padding(8)
                .padding(.vertical, UIDevice.isIPad ? 8 : 0)
                .frame(width: (width == .infinity || width < 0 ? 10 : width))
                .background(isSelected ? AppColors.secondary : AppColors.contrast)
                .cornerRadius(8)
                .shadow(radius: isSelected ? 6 : 2)
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
                        PlayView(name: "\(play.play.down?.fancy() ?? "-") & \(play.play.distance) @ \(play.play.startLine) | \(play.play.odk) | Gain \(play.play.gain)", img: play.photos[0]) {
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

