//
//  AuthActionButtonsView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct AuthActionButtonsView: View {
    let isSignUp: Bool
    let isLoading: Bool
    let onSubmit: () -> Void
    let onToggleMode: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: onSubmit) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill")
                    }
                    Text(isSignUp ? "Create Account" : "Sign In")
                }
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            Button(action: onToggleMode) {
                HStack {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.secondary)
                    Text(isSignUp ? "Sign In" : "Sign Up")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 32)
    }
}
