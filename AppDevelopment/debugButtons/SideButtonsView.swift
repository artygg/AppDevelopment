import SwiftUI

struct SideButtonsView: View {
    let fetchImage: () -> Void
    let openCamera: () -> Void
    let openProfile: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    fetchImage()
                }) {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.purple)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }

                Spacer()

                Button(action: {
                    openCamera()
                }) {
                    Image(systemName: "camera")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }

                Spacer()

                Button(action: {
                    openProfile()
                }) {
                    Image(systemName: "person.crop.circle")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }

                Spacer()
            }
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
