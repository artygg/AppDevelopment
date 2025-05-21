import SwiftUI
import CoreLocation

struct UserProfile: View {
    let username: String
    let lvl: Int
    let capturedPlaces: [Place]
    
    @State private var isProfileIconClicked: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isProfileIconClicked.toggle()
                        }
                    }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .padding()
                            .foregroundColor(.primary)
                    }
                }
            }
            
            if isProfileIconClicked {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isProfileIconClicked = false
                        }
                    }
                
                ProfileView(username: username, lvl: lvl, capturedPlaces: capturedPlaces) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isProfileIconClicked = false
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isProfileIconClicked)
    }

    struct ProfileView: View {
        var username: String
        var lvl: Int
        var capturedPlaces: [Place] = []
        var onClose: () -> Void
        @State private var isSettings: Bool = false

        var body: some View {
            ZStack {
                VStack(spacing: 20) {
                    HStack(alignment: .center) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(username)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.primary)
                            Text("Your lvl: \(lvl)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)

                        Spacer()

                        Button(action: {
                            withAnimation {
                                isSettings.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .padding(8)
                        }
                    }

                    Divider()

                    HStack {
                        HStack {
                            Text("💣 Bombs:")
                                .bold()
                                .foregroundColor(.primary)
                            Text("+10/hr")
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)

                        Spacer()

                        HStack {
                            Text("💥 Mines:")
                                .bold()
                                .foregroundColor(.primary)
                            Text("+20/hr")
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Divider()

                    if capturedPlaces.count > 0 {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(capturedPlaces) { place in
                                    HStack(spacing: 12) {
                                        Image(systemName: place.placeIcon)
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.blue)
                                        Text(place.name)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .frame(height: 5 * 60)
                    } else {
                        VStack {
                            Text("No captured places yet...")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 300)
                    }

                    Divider()

                    Button(action: {
                        onClose()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: 4)
                .frame(maxWidth: .infinity)
                .padding(16)

                if isSettings {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                        .onTapGesture {
                            withAnimation {
                                isSettings = false
                            }
                        }

                    SettinsView(username: username) {
                        withAnimation {
                            isSettings = false
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
                }
            }
        }
    }
}
