//
//  AuthFormView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct AuthFormView: View {
    let isSignUp: Bool
    @ObservedObject var formData: AuthFormData
    
    var body: some View {
        VStack(spacing: 16) {
            AuthTextFieldView(
                title: "Username",
                placeholder: "Enter username",
                text: $formData.username,
                error: formData.usernameError,
                onTextChange: {
                    formData.usernameError = ""
                    formData.credentialsError = ""
                }
            )
            .autocapitalization(.none)
            .autocorrectionDisabled()
            
            if isSignUp {
                AuthTextFieldView(
                    title: "Email",
                    placeholder: "Enter email",
                    text: $formData.email,
                    error: formData.emailError,
                    keyboardType: .emailAddress,
                    onTextChange: {
                        formData.emailError = ""
                        formData.credentialsError = ""
                    }
                )
                .autocapitalization(.none)
                .autocorrectionDisabled()
            }
            
            PasswordFieldView(
                title: "Password",
                placeholder: "Enter password",
                password: $formData.password,
                error: formData.passwordError,
                showRequirements: isSignUp,
                onPasswordChange: {
                    formData.passwordError = ""
                    formData.credentialsError = ""
                }
            )
            
            if isSignUp {
                AuthSecureFieldView(
                    title: "Confirm Password",
                    placeholder: "Confirm password",
                    text: $formData.confirmPassword,
                    error: formData.confirmPasswordError,
                    onTextChange: {
                        formData.confirmPasswordError = ""
                        formData.credentialsError = ""
                    }
                )
            }
        }
        .padding(.horizontal, 32)
    }
}
