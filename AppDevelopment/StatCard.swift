//
//  StatCard.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 25/06/2025.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PlaceCard: View {
    let place: Place
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: place.placeIcon)
                    .font(.title3)
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Lat: \(String(format: "%.4f", place.coordinate.latitude)), Lon: \(String(format: "%.4f", place.coordinate.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 4) {
                Text("No Places Captured Yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Start exploring to capture your first place")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 180)
        .padding(.horizontal, 32)
    }
}

struct SettingsView: View {
    @AppStorage("selectedAvatarURL") var selectedAvatarURL = ""
       @State private var avatarOptions: [ProfileImage] = []
       @State private var isLoadingAvatars = false
       @State private var showAvatarSelection = false
       @State private var errorMessage = ""
       @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile")) {
                    Button(action: {
                        fetchAvatarOptions()
                        showAvatarSelection = true
                    }) {
                        HStack {
                            Text("Change Avatar")
                            Spacer()
                            if !selectedAvatarURL.isEmpty {
                                AsyncImage(url: URL(string: selectedAvatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Preferences")) {
                    NavigationLink(destination: MapSettingsView()) {
                        Text("Map Settings")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Text("Notifications")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                    } label: {
                        Text("Delete Account")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAvatarSelection) {
                AvatarSelectionView(
                    avatars: avatarOptions,
                    isLoading: isLoadingAvatars,
                    selectedAvatarURL: $selectedAvatarURL
                )
            }
        }
        .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: $showAvatarSelection) {
                        AvatarSelectionView(
                            avatars: avatarOptions,
                            isLoading: isLoadingAvatars,
                            selectedAvatarURL: $selectedAvatarURL
                        )
                    }
                    .alert("Error", isPresented: $showError) {
                        Button("OK") { }
                    } message: {
                        Text(errorMessage)
                    }
    }
    
    func fetchAvatarOptions() {
            guard avatarOptions.isEmpty else { return }
            isLoadingAvatars = true
            
            APIService.shared.fetchProfileImages { result in
                isLoadingAvatars = false
                
                switch result {
                case .success(let images):
                    avatarOptions = images
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
}

struct AvatarSelectionView: View {
    let avatars: [ProfileImage]
    let isLoading: Bool
    @Binding var selectedAvatarURL: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(avatars) { avatar in
                        Button {
                            selectedAvatarURL = avatar.url
                            APIService.shared.updateUserMapImage(imageURL: avatar.url) { _ in
                            }
                            dismiss()
                        } label: {
                            VStack {
                                AsyncImage(url: URL(string: avatar.url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedAvatarURL == avatar.url ? Color.blue : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                
                                Text(avatar.name)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct MapSettingsView: View {
    @AppStorage("mapStyle") var mapStyle = "standard"
    
    var body: some View {
        Form {
            Section(header: Text("Map Display")) {
                Picker("Map Style", selection: $mapStyle) {
                    Text("Standard").tag("standard")
                    Text("Satellite").tag("satellite")
                    Text("Hybrid").tag("hybrid")
                }
            }
            
            Section(header: Text("Map Features")) {
                Toggle("Show Traffic", isOn: .constant(false))
                Toggle("Show 3D Buildings", isOn: .constant(true))
            }
        }
        .navigationTitle("Map Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("vibrationEnabled") var vibrationEnabled = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
            
            if notificationsEnabled {
                Section(header: Text("Notification Preferences")) {
                    Toggle("Sound", isOn: $soundEnabled)
                    Toggle("Vibration", isOn: $vibrationEnabled)
                }
                
                Section(header: Text("Notification Types")) {
                    Toggle("New Places Nearby", isOn: .constant(true))
                    Toggle("Friend Activity", isOn: .constant(true))
                    Toggle("Weekly Summary", isOn: .constant(true))
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
