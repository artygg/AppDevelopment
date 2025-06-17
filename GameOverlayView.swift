//
//  GameOverlayView.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 29/04/2025.
//

import SwiftUI

/// Overlay view displaying capture progress, mine count and list of captured places
struct GameOverlayView: View {
    let capturedCount: Int
    let totalCount: Int
    let capturedPlaces: [String]
    let mineCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆 Captured: \(capturedCount)/\(totalCount)")
                    .font(.headline)
                Spacer()
                Label {
                    Text("\(mineCount)")
                        .fontWeight(.semibold)
                } icon: {
                    Image(systemName: "burst.fill")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                Button(action: {
                    // TODO: Settings action
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)

            ProgressView(value: Double(capturedCount), total: Double(totalCount))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(capturedPlaces, id: \.self) { place in
                        Text(place)
                            .font(.subheadline)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Spacer()
                Compass(diameter: 50)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 15)
        }
        .padding(.top, 20)
    }
}

// MARK: - Preview
struct GameOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GameOverlayView(
            capturedCount: 2,
            totalCount: 5,
            capturedPlaces: ["Place A", "Place B"],
            mineCount: 3
        )
        .background(Color.gray.opacity(0.1))
    }
}
