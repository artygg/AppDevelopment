//
//  AuthenticationView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("username") var username = ""
    @AppStorage("userEmail") var userEmail = ""
    
    @State private var isSignUp = false
    @StateObject private var formData = AuthFormData()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AuthHeaderView(isSignUp: isSignUp)
                    
                    if !formData.credentialsError.isEmpty {
                        ErrorMessageView(message: formData.credentialsError)
                    }
                    
                    AuthFormView(
                        isSignUp: isSignUp,
                        formData: formData
                    )
                    
                    AuthActionButtonsView(
                        isSignUp: isSignUp,
                        isLoading: isLoading,
                        onSubmit: submitForm,
                        onToggleMode: toggleMode
                    )
                    
                    Spacer()
                }
            }
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleMode() {
        isSignUp.toggle()
        formData.reset()
        errorMessage = ""
    }
    
    private func submitForm() {
        guard formData.validateForm(isSignUp: isSignUp) else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        formData.credentialsError = ""
        
        if isSignUp {
            APIService.shared.register(
                username: formData.username,
                email: formData.email,
                password: formData.password
            ) { result in
                handleAuthResult(result)
            }
        } else {
            APIService.shared.login(
                username: formData.username,
                password: formData.password
            ) { result in
                handleAuthResult(result)
            }
        }
    }
    
    private func handleAuthResult(_ result: Result<AuthResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            username = response.user.username
            userEmail = response.user.email
            isLoggedIn = true
            print("Login successful for user: \(response.user.username)")
            dismiss()
            
        case .failure(let error):
            formData.handleAuthError(error)
        }
    }
}
