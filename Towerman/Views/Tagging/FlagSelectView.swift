//
//  FlagSelectView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import SwiftUI

struct FlagSelectView: View {
    @Binding var selected: Bool
    var body: some View {
        VStack(spacing: 8) {
            Text("FLAG")
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Button(action: { selected = !selected } ) {
                Image(systemName: selected ? "flag" : "flag.slash")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.vertical, 22)
                    .frame(width: 64)
                    .foregroundColor(.white)
                    .background(selected ? AppColors.secondary : AppColors.contrast)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(selected ? 0.4 : 0), radius: 8)
            }
        }
    }
}
