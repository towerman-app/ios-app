//
//  NumberSelectView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import SwiftUI

struct XNumberSelectView: View {
    let title: String
    @Binding var value: Int
    @Binding var pad: NumberPadView.For
    let selected: NumberPadView.For
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text(String(value))
                .padding(.vertical, 24)
                .frame(width: 64)
                .background(content: {
                    Group {
                        AppColors.contrast
                        if pad == selected {
                            AppColors.secondary.opacity(0.5)
                        }
                    }
                })
                .cornerRadius(8)
                .shadow(radius: pad == selected ? 6 : 0)
                .onTapGesture {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        pad = selected
                    }
                }
        }
    }
}


struct NumberSelectView: View {
    let title: String
    let value: Int?
    @Binding var pad: NumberPadView.For
    let selected: NumberPadView.For
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text(value == nil ? "0" : String(value!))
                .padding(.vertical, 24)
                .frame(width: 64)
                .background(content: {
                    Group {
                        AppColors.contrast
                        if pad == selected {
                            AppColors.secondary.opacity(0.5)
                        }
                    }
                })
                .foregroundColor(.white.opacity(value == nil ? 0 : 1))
                .cornerRadius(8)
                .shadow(radius: pad == selected ? 6 : 0)
                .onTapGesture {
                    if value == nil { return }
                    withAnimation(Animation.linear(duration: 0.1)) {
                        pad = selected
                    }
                }
        }
    }
}
