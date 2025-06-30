//
//  AuthFormData.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

class AuthFormData: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var usernameError = ""
    @Published var emailError = ""
    @Published var passwordError = ""
    @Published var confirmPasswordError = ""
    @Published var credentialsError = ""
    
    func reset() {
        username = ""
        email = ""
        password = ""
        confirmPassword = ""
        
        usernameError = ""
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        credentialsError = ""
    }
    
    func clearErrors() {
        usernameError = ""
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        credentialsError = ""
    }
    
    func validateForm(isSignUp: Bool) -> Bool {
        var isValid = true
        clearErrors()
        
        if username.isEmpty {
            usernameError = "Username is required"
            isValid = false
        } else if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            isValid = false
        } else if username.count > 20 {
            usernameError = "Username must be less than 20 characters"
            isValid = false
        } else if !username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }) {
            usernameError = "Username can only contain letters, numbers, underscores, and hyphens"
            isValid = false
        }
        
        if isSignUp {
            if email.isEmpty {
                emailError = "Email is required"
                isValid = false
            } else if !isValidEmail(email) {
                emailError = "Please enter a valid email address"
                isValid = false
            }
        }
        
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else if isSignUp {
            if password.count < 8 {
                passwordError = "Password must be at least 8 characters"
                isValid = false
            } else if !password.contains(where: { $0.isUppercase }) {
                passwordError = "Password must contain at least one uppercase letter"
                isValid = false
            } else if !password.contains(where: { $0.isNumber }) {
                passwordError = "Password must contain at least one number"
                isValid = false
            } else if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) {
                passwordError = "Password must contain at least one special character"
                isValid = false
            }
        } else {
            if password.count < 6 {
                passwordError = "Password must be at least 6 characters"
                isValid = false
            }
        }
        
        if isSignUp {
            if confirmPassword.isEmpty {
                confirmPasswordError = "Please confirm your password"
                isValid = false
            } else if password != confirmPassword {
                confirmPasswordError = "Passwords don't match"
                isValid = false
            }
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    func handleAuthError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .authError(let message):
                if message.lowercased().contains("invalid") ||
                    message.lowercased().contains("incorrect") ||
                    message.lowercased().contains("wrong") ||
                    message.lowercased().contains("credentials") {
                    credentialsError = message
                } else if message.lowercased().contains("username") {
                    usernameError = message
                } else if message.lowercased().contains("email") {
                    emailError = message
                } else if message.lowercased().contains("password") {
                    passwordError = message
                } else {
                    credentialsError = message
                }
                
            case .serverError(let code):
                switch code {
                case 401:
                    credentialsError = "Invalid username or password"
                case 409:
                    credentialsError = "Account already exists with these credentials"
                case 422:
                    credentialsError = "Please check your information and try again"
                default:
                    credentialsError = "Server error (code \(code)). Please try again later."
                }
                
            default:
                credentialsError = "An unexpected error occurred. Please try again."
            }
        } else {
            credentialsError = error.localizedDescription
        }
    }
}
