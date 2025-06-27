//
//  SettingsView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-27.
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @AppStorage("selectedAvatarURL") private var selectedAvatarURL = ""
    @Environment(\.colorScheme)     private var scheme
    @State private var showImagePicker = false

    private var background: some View {
        LinearGradient(
            colors: scheme == .dark ? [.black, .indigo] : [.white, .blue.opacity(0.25)],
            startPoint: .topLeading,
            endPoint:   .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // ─────── avatar row
                    SectionCard {
                        HStack {
                            Text("Change Avatar")
                                .font(.headline)
                            Spacer()

                            if  let url   = URL(string: selectedAvatarURL),
                                let data  = try? Data(contentsOf: url),
                                let uiImg = UIImage(data: data) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 46, height: 46)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                                    .shadow(radius: 3)
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { showImagePicker = true }
                    }

                    // ─────── preferences
                    SectionHeader("Preferences")

                    VStack(spacing: 18) {
                        NavigationLink {
                            MapSettingsView()          // ← separate file
                        } label: {
                            ActionRow(title: "Map Settings", systemImage: "map")
                        }

                        NavigationLink {
                            NotificationSettingsView() // ← separate file
                        } label: {
                            ActionRow(title: "Notifications", systemImage: "bell.badge")
                        }
                    }

                    // ─────── danger zone
                    SectionHeader("Danger Zone")

                    SectionCard {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Delete Account")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
            }
            .background(background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ProfileImagePicker(selectedAvatarURL: $selectedAvatarURL)
                    .presentationDetents([.large])
            }
        }
    }
}

// ───────────────────────── helpers ─────────────────────────

private struct SectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content
    init(@ViewBuilder _ content: () -> Content) { self.content = content() }
    var body: some View {
        VStack { content }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Color(.systemBackground).opacity(scheme == .dark ? 0.2 : 0.95),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ text: String) { title = text.uppercased() }
    var body: some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

private struct ActionRow: View {
    let title: String
    let systemImage: String
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
