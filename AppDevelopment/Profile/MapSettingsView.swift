//
//  MapSettingsView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-27.
//

import SwiftUI

struct MapSettingsView: View {
    @AppStorage("mapStyle") private var mapStyle = "standard"
    @Environment(\.colorScheme) private var scheme

    private var background: some View {
        LinearGradient(
            colors: scheme == .dark ? [.black, .indigo] : [.white, .blue.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View {
        VStack(spacing: 24) {
            Picker("Map Style", selection: $mapStyle) {
                Text("Standard").tag("standard")
                Text("Satellite").tag("satellite")
                Text("Hybrid").tag("hybrid")
            }
            .pickerStyle(.segmented)

            Toggle("Show Traffic",      isOn: .constant(false))
            Toggle("Show 3D Buildings", isOn: .constant(true))

            Spacer()
        }
        .padding()
        .background(background)
        .navigationTitle("Map Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
