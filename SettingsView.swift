import SwiftUI

import SwiftUI

struct SettingsView: View {
    var username: String
    var onClose: () -> Void
    @State private var showingAvatarSelection = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .bold()
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
            }

            Divider()

            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(username)
                        .font(.headline)
                    Text("Signed in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            VStack(spacing: 16) {
                SettingsRow(icon: "bell.fill", label: "Notifications")
                SettingsRow(icon: "lock.fill", label: "Privacy")

                SettingsRow(icon: "paintbrush.fill", label: "Appearance")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingAvatarSelection = true
                    }

                SettingsRow(icon: "questionmark.circle.fill", label: "Help & Support")
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAvatarSelection) {
            AvatarSelectionView()
        }
    }
}
    

struct AvatarSelectionView: View {
    let avatars = ["person.circle.fill", "person.fill", "person.2.circle.fill",
                   "person.3.fill", "face.smiling.fill", "person.crop.circle.fill"]
    
    @State private var selectedAvatar: String = "person.circle.fill"
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                HStack(spacing: 6) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                    }
                    .foregroundColor(.blue)

                    Spacer()
                }
                .padding(.top)
                
                Text("Select Avatar")
                    .font(.title2)
                    .bold()
                
                HStack {
                    Spacer()
                    Image(systemName: selectedAvatar)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(avatars, id: \.self) { avatar in
                        AvatarButton(
                            systemName: avatar,
                            isSelected: avatar == selectedAvatar
                        ) {
                            selectedAvatar = avatar
                        }
                    }
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .background(
            colorScheme == .dark ? Color(.systemGroupedBackground) : Color(.systemBackground)
        )
    }
}

struct AvatarButton: View {
    let systemName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(isSelected ? .white : .blue)
                .padding()
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: isSelected ? 0 : 1)
                        )
                )
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(label)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .foregroundColor(.primary)
    }
}
