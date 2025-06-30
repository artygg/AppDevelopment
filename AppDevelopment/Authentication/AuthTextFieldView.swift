//
//  AuthTextFieldView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct AuthTextFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let error: String
    var keyboardType: UIKeyboardType = .default
    let onTextChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
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

