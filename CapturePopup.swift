//
//  CapturePopup.swift
//  AppDevelopment
//
//  Created by Ekaterina Tarlykova on 2025-05-22.
//

import SwiftUI

struct CapturePopup: View {
    let place: DecodedPlace
    let onClose: () -> Void
    let onCapture: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 18) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                Text("You can capture \"\(place.name)\"")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Button("Capture", action: onCapture)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .shadow(radius: 12)
            .padding(.horizontal, 36)
            Spacer().frame(height: 200)
        }
        .transition(.scale)
        .zIndex(10)
    }
}
