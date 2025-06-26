//
//  CapturePopup.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-17.
//

import SwiftUI

struct CapturePopup: View {
    // MARK: – Input
    let place: DecodedPlace
    let onClose: () -> Void
    let onCapture: () -> Void

    // MARK: – State
    @State private var photo:   Image? = nil
    @State private var loaded           = false
    @Environment(\.colorScheme) private var scheme

    // MARK: – Body
    var body: some View {
        ZStack {
            // ▸ dim-behind overlay
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onClose() }

            mainCard
                .padding(.horizontal, 32)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                        removal: .opacity))
                .task { await loadPhoto() }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: photo)
    }

    // MARK: – Card
    private var mainCard: some View {
        VStack(spacing: 24) {
            // close ––––––––––––––––––––––––––––––––––––––––––––
            HStack { Spacer(); closeButton }

            // image –––––––––––––––––––––––––––––––––––––––––––
            photoBlock
                .frame(maxWidth: .infinity)
                .aspectRatio(1.5, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                )

            // title –––––––––––––––––––––––––––––––––––––––––––
            VStack(spacing: 4) {
                Text("Ready to capture")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("“\(place.name)”")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal)

            // action –––––––––––––––––––––––––––––––––––––––––––
            captureButton
        }
        .padding(28)
        .frame(maxWidth: 460)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(Color.primary.opacity(scheme == .dark ? 0.15 : 0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.6 : 0.2), radius: 18, y: 6)
    }

    // MARK: – Components
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .padding(10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .background(Circle().fill(.ultraThinMaterial))
    }

    @ViewBuilder
    private var photoBlock: some View {
        if let img = photo {
            img
                .resizable()
                .scaledToFill()
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.35)],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
        } else if !loaded {
            ProgressView()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("No previous photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var captureButton: some View {
        Button(action: onCapture) {
            Text("Capture")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(buttonGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }

    // MARK: – Helpers
    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: scheme == .dark
            ? [Color.indigo, Color.purple]
            : [Color.blue,   Color.indigo],
            startPoint: .leading,
            endPoint: .trailing)
    }

    private var cardBackground: some View {
        BlurView(style: .systemUltraThinMaterial)
            .background(
                (scheme == .dark ? Color.black : Color.white)
                    .opacity(0.15))
    }

    private func loadPhoto() async {
        guard
            let url      = URL(string: "\(Config.apiURL)/get-image?place_id=\(place.id)"),
            let (data,_) = try? await URLSession.shared.data(from: url),
            let uiImg    = UIImage(data: data)
        else {
            loaded = true
            return
        }

        await MainActor.run {
            self.photo = Image(uiImage: uiImg)
            self.loaded = true
        }
    }
}

// MARK: – Blur helper
private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
