import SwiftUI

struct GameOverlayView: View {
    let capturedCount:Int
    let totalCount:Int
    let capturedPlaces:[String]
    @Binding var autoFocusEnabled:Bool
    let mineCount:Int
    var openBoard:()->Void = {}

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            glassPanel
            compassStack
        }
        .padding(.top, 6)
        .animation(.easeOut(duration:0.25), value:mineCount+capturedCount)
    }

    private var glassPanel: some View {
        VStack(alignment:.leading, spacing:10) {
            topRow
            ProgressView(value:Double(capturedCount), total:Double(totalCount))
                .tint(.accentColor)
                .frame(height:3)
                .padding(.horizontal,20)
            chips
        }
        .padding(.vertical,10)
        .background(
            LinearGradient(colors:
                           scheme == .dark
                           ? [Color.black.opacity(0.45), Color.blue.opacity(0.35)]
                           : [Color.white.opacity(0.85), Color.blue.opacity(0.15)],
                           startPoint:.topLeading, endPoint:.bottomTrailing)
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:26, style:.continuous))
        .overlay(RoundedRectangle(cornerRadius:26).stroke(Color.white.opacity(0.08), lineWidth:0.8))
        .shadow(color:.black.opacity(0.18), radius:10, y:5)
        .padding(.horizontal,14)
    }

    private var topRow: some View {
        HStack {
            pill(icon:"trophy.fill", value:"\(capturedCount)/\(totalCount)", tint:.yellow, tap:openBoard)
            Spacer()
            pill(icon:"sparkles.rectangle.stack.fill", value:"\(mineCount)", tint:.pink)
        }
        .padding(.horizontal,20)
    }

    @ViewBuilder
    private var chips: some View {
        if !capturedPlaces.isEmpty {
            ScrollView(.horizontal, showsIndicators:false) {
                HStack(spacing:8) {
                    ForEach(capturedPlaces,id:\.self) {
                        Text($0)
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal,12)
                            .padding(.vertical,4)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(scheme == .dark ? 0.25 : 0.18))
                            )
                    }
                }
                .padding(.horizontal,20)
            }
            .frame(height:28)
        }
    }

    private var compassStack: some View {
        VStack(spacing:10) {
            Compass(diameter:46)
            Button {
                autoFocusEnabled.toggle()
                UIImpactFeedbackGenerator(style:.soft).impactOccurred()
            } label: {
                Image(systemName:autoFocusEnabled ? "location.fill" : "location.slash.fill")
                    .font(.system(size:17, weight:.bold))
                    .foregroundStyle(.white)
                    .frame(width:40, height:40)
                    .background(
                        Circle().fill(
                            autoFocusEnabled
                            ? Color.accentColor
                            : Color.gray.opacity(0.6))
                    )
            }
        }
        .padding(.trailing,24)
        .padding(.top,110)   // moved lower
    }

    @ViewBuilder
    private func pill(icon:String, value:String, tint:Color, tap:(()->Void)?=nil) -> some View {
        Group {
            if let tap = tap {
                Button(action:tap) { pillContent(icon,value,tint) }.buttonStyle(.plain)
            } else {
                pillContent(icon,value,tint)
            }
        }
    }

    private func pillContent(_ icon:String, _ value:String, _ tint:Color) -> some View {
        HStack(spacing:6) {
            Image(systemName:icon).font(.system(size:16, weight:.bold)).foregroundStyle(tint)
            Text(value).font(.headline.weight(.semibold)).foregroundStyle(.primary)
        }
        .padding(.horizontal,14)
        .padding(.vertical,6)
        .background(Capsule().fill(Color.primary.opacity(scheme == .dark ? 0.18 : 0.07)))
    }
}
