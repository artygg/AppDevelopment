//
//  NotificationSettingsView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-27.
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled")         private var soundEnabled         = true
    @AppStorage("vibrationEnabled")     private var vibrationEnabled     = true
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
            Toggle("Enable Notifications", isOn: $notificationsEnabled)

            if notificationsEnabled {
                VStack(spacing: 16) {
                    Toggle("Sound",     isOn: $soundEnabled)
                    Toggle("Vibration", isOn: $vibrationEnabled)
                }
                .padding()
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 16) {
                    Toggle("New Places Nearby", isOn: .constant(true))
                    Toggle("Friend Activity",   isOn: .constant(true))
                    Toggle("Weekly Summary",    isOn: .constant(true))
                }
                .padding()
                .background(Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .background(background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
