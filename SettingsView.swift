import SwiftUI

struct SettinsView: View {
    var username: String
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(username)
                        .font(.headline)
                        .foregroundColor(.primary)
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
                SettingsRow(icon: "questionmark.circle.fill", label: "Help & Support")
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .frame(height: 600)
    }
}

struct SettingsRow: View {
    var icon: String
    var label: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
