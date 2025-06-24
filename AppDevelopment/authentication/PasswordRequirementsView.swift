//
//  PasswordRequirementsView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct PasswordRequirementsView: View {
    let password: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password Requirements:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            PasswordRequirementRow(
                text: "At least 8 characters",
                isMet: password.count >= 8
            )
            
            PasswordRequirementRow(
                text: "Contains uppercase letter",
                isMet: password.contains(where: { $0.isUppercase })
            )
            
            PasswordRequirementRow(
                text: "Contains number",
                isMet: password.contains(where: { $0.isNumber })
            )
            
            PasswordRequirementRow(
                text: "Contains special character (!@#$%^&*)",
                isMet: password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) })
            )
        }
    }
}
