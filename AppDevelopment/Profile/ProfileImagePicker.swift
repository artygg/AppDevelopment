//
//  ProfileImagePicker.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-27.
//

import SwiftUI
import PhotosUI

// Public façade: present with `.sheet { ProfileImagePicker(selectedAvatarURL: …) }`
struct ProfileImagePicker: View {

    // The URL string you persist in @AppStorage
    @Binding var selectedAvatarURL: String

    // Work state
    @State private var pickedItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                avatarPreview

                PhotosPicker("Choose from library",
                             selection: $pickedItem,
                             matching: .images,
                             photoLibrary: .shared())
                    .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .navigationTitle("Select Avatar")
            .toolbar { saveToolbar }
            .onChange(of: pickedItem) { _ in loadImage() }
            .interactiveDismissDisabled(false)
        }
    }

    // ─── live preview
    private var avatarPreview: some View {
        Group {
            if let img = previewImage {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let url = URL(string: selectedAvatarURL),
                      let data = try? Data(contentsOf: url),
                      let img  = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable().scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .clipShape(Circle())
        .shadow(radius: 8, y: 4)
        .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
    }

    // ─── toolbar buttons
    @ToolbarContentBuilder
    private var saveToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") { persistAndDismiss() }
                .disabled(previewImage == nil)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", role: .cancel) { dismiss() }
        }
    }

    // ─── helpers
    private func loadImage() {
        guard let item = pickedItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImg = UIImage(data: data) {
                await MainActor.run { previewImage = uiImg }
            }
        }
    }

    private func persistAndDismiss() {
        guard let img  = previewImage,
              let data = img.jpegData(compressionQuality: 0.85) else { return }

        do {
            let url = try saveImage(data: data)
            selectedAvatarURL = url.absoluteString   // store in AppStorage
            dismiss()
        } catch {
            print("❌ Avatar save failed:", error.localizedDescription)
        }
    }

    /// Saves to <App-Sandbox>/Documents/Avatars/<UUID>.jpg
    private func saveImage(data: Data) throws -> URL {
        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir  = docs.appendingPathComponent("Avatars", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let file = dir.appendingPathComponent(UUID().uuidString + ".jpg")
        try data.write(to: file, options: .atomic)
        return file
    }
}
