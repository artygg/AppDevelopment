import SwiftUI

struct UserProfile: View {
    let username: String
    let lvl: Int

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

                ProfileView(username: username, lvl: lvl) {
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
        var onClose: () -> Void

        var body: some View {
            VStack(spacing: 20) {
                HStack(alignment: .center) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(username)")
                            .font(.title2)
                            .bold()
                        Text("Your lvl: \(lvl)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Button(action: {
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
                
                Divider()
                
                HStack {
                    HStack {
                        Text("💣 Bombs:")
                            .bold()
                        Text("+10/hr")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    HStack {
                        Text("💥 Mines:")
                            .bold()
                        Text("+20/hr")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
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
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
    }

    struct UserProfile_Previews: PreviewProvider {
        static var previews: some View {
            UserProfile(username: "sofro", lvl: 12)
        }
    }
}
