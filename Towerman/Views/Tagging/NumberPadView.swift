//
//  NumberPadView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import SwiftUI

struct NumberPadView: View {
    @Binding var forType: NumberPadView.For
    @Binding var value: Int
    @State private var startNumber: Int = 0
    @ObservedObject var taggingManager: TaggingManager

    var body: some View {
        ZStack {
            if forType != .none {
                Color.clear.contentShape(Rectangle()).edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        value = startNumber
                        
                        withAnimation(Animation.linear(duration: 0.1)) {
                            forType = .none
                        }
                    }
            }
            
            HStack {
                Spacer()
                if forType != .none {
                    Pad(forType: $forType, value: $value, startNumber: $startNumber, taggingManager: taggingManager)
                        .transition(.move(edge: .trailing))
                }
            }
        }
    }
    
    struct Pad: View {
        @Binding var forType: NumberPadView.For
        @Binding var value: Int
        @Binding var startNumber: Int
        @ObservedObject var taggingManager: TaggingManager
        
        @State private var isNegative = false
        @State private var text = ""
        @State private var width: CGFloat? = nil
                
        var body: some View {
            VStack {
                Text(String(value))
                    .onChange(of: text) { newValue in
                        if isNegative && Int(newValue)! >= 0 {
                            text = "-" + newValue
                            isNegative = false

                        }
                        value = Int(text)!
                    }
                    .onChange(of: value) { newValue in
                        text = String(newValue)
                    }
                
                HStack {
                    ForEach(1..<4) { idx in
                        Cell(title: String(idx)) {
                            text += String(idx)
                        }
                    }
                }
                
                HStack {
                    ForEach(4..<7) { idx in
                        Cell(title: String(idx)) {
                            text += String(idx)
                        }
                    }
                }
                
                HStack {
                    ForEach(7..<10) { idx in
                        Cell(title: String(idx)) {
                            text += String(idx)
                        }
                    }
                }
                
                HStack {
                    Cell(title: "-") {
                        value *= -1
                        if text.isEmpty || value == 0 {
                            value = 0
                            isNegative = !isNegative
                        }
                    }
                    
                    Cell(title: "0") {
                        text += "0"
                    }
                    
                    Cell(img: "arrow.backward") {
                        value = 0
                        isNegative = false
                    }
                }
                
                Button(action: {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        switch (forType) {
                        case .series:
                            taggingManager.modify(series: value)

                        case .distance:
                            taggingManager.modify(distance: value)

                        case .startLine:
                            taggingManager.modify(startLine: value)

                        case .endLine:
                            taggingManager.modify(endLine: value)

                        case .none:
                            return
                        }
                        forType = .none
                    }
                    
                }) {
                    Text("ENTER")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .frame(width: width ?? 0)
                        .background(AppColors.secondary)
                        .cornerRadius(4)
                }
            }
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.size.width, perform: { newValue in
                            width = newValue
                        })
                }
            }
            .padding(12)
            .background(AppColors.contrast)
            .cornerRadius(16)
            .padding(8)
            .onAppear {
                startNumber = value
                isNegative = false
            }
        }
    }
    
    struct Cell: View {
        let img: String?
        let title: String?
        let onClick: () -> Void
        @State private var height: CGFloat? = nil
        
        init(img: String? = nil, title: String? = nil, onClick: @escaping () -> Void) {
            self.img = img
            self.title = title
            self.onClick = onClick
        }
        var body: some View {
            Button(action: onClick) {
                Group {
                    if let name = title {
                        Text(name)
                            .lineLimit(1)
                    } else {
                        Image(systemName: img!)
                            .resizable()
                            .frame(width: 16, height: 12)
                    }
                }
                    .foregroundColor(.white)
                    .frame(width: height ?? 0)
                    .frame(maxHeight: .infinity)
                    .background(AppColors.primary)
                    .cornerRadius(4)
                    .overlay {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    height = geo.size.height
                                }
                        }
                    }
            }
        }
    }
    
    enum For {
        case distance
        case startLine
        case endLine
        case series
        case none
    }
}
