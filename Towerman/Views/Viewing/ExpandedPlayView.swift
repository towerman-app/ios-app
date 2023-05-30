//
//  ExpandedPlayView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-05-08.
//

import SwiftUI

struct ExpandedPlayView: View {
    let onExit: () -> Void
    let play: SeriesPlay
    
    @State private var offsetX: CGFloat = 0
    @State private var currentIdx: Int = 0
    @State private var screenSize: CGSize = CGSize(width: 0, height: 0)
    @GestureState private var isPressed = false
    
    // Drawing
    @State private var selectedColor = Color.black
    @State private var isDrawing = false
    @State private var drawings: [Drawing] = [Drawing]()
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        screenSize = geo.size
                    }
            }
            
            ForEach(0..<play.photos.count) { idx in
                
                let drag = DragGesture(minimumDistance: 12)
                    .updating($isPressed) { (value, gestureState, transaction) in
                        gestureState = true
                    }
                ZoomableScrollView {
                    Image(uiImage: play.photos[idx])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            Pad(drawings: $drawings, color: selectedColor, isDrawing: isDrawing)
                        }
                    
                }
                .offset(x: offsetX + (screenSize.width + 12) * CGFloat(idx - currentIdx))
                .gesture(drag
                    .onChanged({ value in
                        if (currentIdx == 0 && value.translation.width > 0) || (currentIdx == play.photos.count - 1 && value.translation.width < 0) {
                            offsetX = value.translation.width * 0.2
                        } else {
                            offsetX = value.translation.width
                        }
                        
                    })
                        .onEnded({ value in
                            withAnimation(Animation.linear(duration: 0.2)) {
                                offsetX = 0
                                
                                if value.predictedEndTranslation.width < screenSize.width / -2 && currentIdx < play.photos.count - 1 {
                                    currentIdx += 1
                                    drawings = []
                                } else if value.predictedEndTranslation.width > screenSize.width / 2 && currentIdx > 0 {
                                    currentIdx -= 1
                                    drawings = []
                                }
                            }
                            
                        }))
                .onChange(of: isPressed) { newValue in
                    if !isPressed {
                        withAnimation(Animation.linear(duration: 0.2)) {
                            offsetX = 0
                        }
                    }
                }
            }
            
            HStack {
                DrawSelector(selectedColor: $selectedColor, isDrawing: $isDrawing, undo: {
                    if !drawings.isEmpty {
                        drawings.removeLast()
                    }
                }, reset: {
                    drawings = []
                })
                Spacer()
                VStack {
                    Button(action: {
                        withAnimation(Animation.linear(duration: 0.2)) {
                            onExit()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(.gray)
                            .clipShape(Circle())
                    }
                    .padding(12)
                    Spacer()
                }
            }
            
            VStack {
                let p = play.play
                let keys: [(String, String)] = [
                    ("Q", String(p.quarter)),
                    ("ODK", p.odk),
                    ("DN", p.down == nil ? "" : String(p.down!)),
                    ("DST", String(p.distance)),
                    ("ST", String(p.startLine)),
                    ("END", String(p.endLine)),
                    ("S", String(p.series))
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
                    
                    if p.flagged {
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
                .frame(maxWidth: UIScreen.screenWidth * 0.6)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Text("\(currentIdx + 1)/\(play.photos.count)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(20)
            
        }
        
    }
}

struct DrawSelector: View {
    @Binding var selectedColor: Color
    @Binding var isDrawing: Bool
    let undo: () -> Void
    let reset: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            Button(action: {
                withAnimation(Animation.linear(duration: 0.2)) {
                    isDrawing = !isDrawing
                } }) {
                    Image(systemName: isDrawing ? "checkmark" : "scribble")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(AppColors.secondary)
                        .clipShape(Circle())
                        .padding(4)
                        .background(isDrawing ? .clear : .black)
                        .clipShape(Circle())
                }
            
            if isDrawing {
                Group {
                    Button(action: undo) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                    
                    Button(action: reset) {
                        Image(systemName: "trash")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(AppColors.secondary)
                            .clipShape(Circle())
                    }
                    
                    ColorButton(color: .black, selected: selectedColor == .black)
                        .onTapGesture {
                            selectedColor = .black
                        }
                    
                    ColorButton(color: .red, selected: selectedColor == .red)
                        .onTapGesture {
                            selectedColor = .red
                        }
                    
                    ColorButton(color: .yellow, selected: selectedColor == .yellow)
                        .onTapGesture {
                            selectedColor = .yellow
                        }
                }
                .transition(.move(edge: .bottom))
                
            }
        }
        .padding(8)
        .background(isDrawing ? .black.opacity(0.5) : AppColors.secondary.opacity(0))
        .cornerRadius(isDrawing ? 8 : 32)
        .padding(.leading, 16)
    }
    
    private struct ColorButton: View {
        let color: Color
        let selected: Bool
        
        var body: some View {
            Circle()
                .strokeBorder(selected ? Color.white : Color.clear, lineWidth: 4)
                .animation(.linear, value: selected)
                .background(Circle().foregroundColor(color))
                .frame(width: 32, height: 32)
        }
    }
}

struct Drawing: Identifiable {
    let id = UUID()
    let color: Color
    var points: [CGPoint] = [CGPoint]()
}

struct Pad: View {
    @Binding var drawings: [Drawing]
    let color: Color
    let isDrawing: Bool
    @State private var currentDrawing: Drawing = Drawing(color: .black)
    @State private var lineWidth: CGFloat = 4.0
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(drawings) { drawing in
                Path { path in
                    self.add(drawing: drawing, toPath: &path)
                }
                .stroke(drawing.color, lineWidth: self.lineWidth)
            }
            
            Path { path in
                self.add(drawing: self.currentDrawing, toPath: &path)
            }
            .stroke(currentDrawing.color, lineWidth: self.lineWidth)
            .background(isDrawing ? .black.opacity(0.1) : .clear)
                .gesture(
                    DragGesture(minimumDistance: 0.1)
                        .onChanged({ (value) in
                            let currentPoint = value.location
                            if currentPoint.y >= 0
                                && currentPoint.y < geometry.size.height {
                                self.currentDrawing.points.append(currentPoint)
                            }
                        })
                        .onEnded({ (value) in
                            self.drawings.append(self.currentDrawing)
                            self.currentDrawing = Drawing(color: self.color)
                        })
            )
                .onChange(of: color) { newValue in
                    self.currentDrawing = Drawing(color: newValue)
                }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func add(drawing: Drawing, toPath path: inout Path) {
        let points = drawing.points
        if points.count > 1 {
            for i in 0..<points.count-1 {
                let current = points[i]
                let next = points[i+1]
                path.move(to: current)
                path.addLine(to: next)
            }
        }
    }
}

struct DrawingPad: View {
    @State private var selectedColor = Color.black
    @State private var isDrawing = false
    
    @State private var drawings: [Drawing] = [Drawing]()
    
    var body: some View {
        Pad(drawings: $drawings, color: selectedColor, isDrawing: isDrawing)
        ZStack {
            HStack {
                DrawSelector(selectedColor: $selectedColor, isDrawing: $isDrawing, undo: {
                    if !drawings.isEmpty {
                        drawings.removeLast()
                    }
                }, reset: {
                    drawings = []
                })
                Spacer()
            }
            
        }
    }
}
