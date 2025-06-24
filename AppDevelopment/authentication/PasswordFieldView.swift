//
//  PasswordFieldView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct PasswordFieldView: View {
    let title: String
    let placeholder: String
    @Binding var password: String
    let error: String
    let showRequirements: Bool
    let onPasswordChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            SecureField(placeholder, text: $password)
                .textFieldStyle(.roundedBorder)
                .onChange(of: password) { _ in
                    onPasswordChange()
                }
            
            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if showRequirements && !password.isEmpty {
                PasswordRequirementsView(password: password)
                    .padding(.top, 4)
            }
        }
    }
}
