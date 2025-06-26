import SwiftUI

struct GameOverlayView: View {
    let capturedCount:  Int
    let totalCount:     Int
    let capturedPlaces: [String]
    @Binding var autoFocusEnabled: Bool

    let mineCount:      Int
    var openBoard:     () -> Void = {}

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: openBoard) {
                        Label("\(capturedCount)/\(totalCount)",
                              systemImage: "trophy.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.plain)

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
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)

                ProgressView(value: Double(capturedCount),
                             total: Double(totalCount))
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

                Spacer()
            }

            VStack(spacing: 10) {
                Compass(diameter: 50)

                Button(action: {
                    autoFocusEnabled.toggle()
                    if autoFocusEnabled {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    Image(systemName: autoFocusEnabled ? "location.fill" : "location.slash.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(autoFocusEnabled ? Color.blue.opacity(0.8) : Color.gray.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 85)
            .padding(.trailing, 20)
        }
        .padding(.top, 20)
    }
}

struct GameOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GameOverlayView(
            capturedCount: 2,
            totalCount: 5,
            capturedPlaces: ["Place A", "Place B"],
            autoFocusEnabled: .constant(true),
            mineCount: 3
        )
        .background(Color.gray.opacity(0.1))
    }
}
