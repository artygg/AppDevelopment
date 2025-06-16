//
//  SideButtonsView.swift
//  AppDevelopment
//
//  Created by Timofei Arefev on 16/06/2025.
//

import SwiftUI

struct SideButtonsView: View {
    let fetchImage: () -> Void
    let openCamera: () -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
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
            }
            .padding(.leading, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
