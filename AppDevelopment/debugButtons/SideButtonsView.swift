import SwiftUI

struct SideButtonsView: View {
    let fetchImage: () -> Void
    let openCamera: () -> Void
    let openProfile: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 46) {
                FancyFAB(symbol: "photo.on.rectangle", gradient: [.purple, .pink], action: fetchImage)
                FancyFAB(symbol: "camera.fill",        gradient: [.blue,   .cyan], action: openCamera)
                FancyFAB(symbol: "person.crop.circle.fill", gradient: [.gray,  .black.opacity(0.7)], action: openProfile)
            }
            .padding(.bottom, 50)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct FancyFAB: View {
    let symbol: String
    let gradient: [Color]
    let action: () -> Void

    @State private var pressed = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: gradient,
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing))
                            .blur(radius: 16)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: gradient,
                                               startPoint: .top,
                                               endPoint: .bottom),
                                lineWidth: 3
                            )
                            .blur(radius: 0.5)
                    )
                    .shadow(color: gradient.last!.opacity(pressed ? 0.2 : 0.4),
                            radius: pressed ? 6 : 12,
                            y: pressed ? 2 : 6)

                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(scheme == .dark ? .white : .black)
            }
            .frame(width: 68, height: 68)
            .scaleEffect(pressed ? 0.94 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                       value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}
