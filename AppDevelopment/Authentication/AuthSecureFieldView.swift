//
//  AuthSecureFieldView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct AuthSecureFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let error: String
    let onTextChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            SecureField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { _ in
                    onTextChange()
                }
            
            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}
