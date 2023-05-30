//
//  ErrorStackView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-04-16.
//

import SwiftUI

struct ErrorStackView: View {
    let errors: [String]
    var body: some View {
        HStack {
            Spacer()
            VStack {
                ForEach(errors.indices, id: \.self) { idx in
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.red)
                        Text(errors[idx])
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(AppColors.contrast)
                    .cornerRadius(8)
                    .padding(4)
                    .transition(.opacity.combined(with: .asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom))))
                }
                
                Spacer()
            }
        }
    }
}
