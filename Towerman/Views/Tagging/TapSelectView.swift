//
//  TapSelectView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import Foundation
import SwiftUI

struct TapSelectView<T: Hashable>: View {
    
    let title: String
    let options: [T]
    @Binding var selected: T
    @State var nulled: T?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            ForEach(options, id: \.self) { idx in
                Button(action: {
                    if selected == idx && nulled != nil {
                        selected = nulled!
                    } else {
                        selected = idx
                    }
                }) {
                    VStack {
                        Spacer()
                        Text(idx is String ? idx as! String : idx is Int ? String(idx as! Int) : "")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .background((idx == selected ? AppColors.secondary : AppColors.contrast))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(idx == selected ? 0.4 : 0), radius: 8)
                }
            }
        }
        .padding(.vertical, 32)
    }
}
