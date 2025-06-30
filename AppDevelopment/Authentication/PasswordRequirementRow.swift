//
//  Password.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .green : .secondary)
                .strikethrough(isMet, color: .green)
        }
        .animation(.easeInOut(duration: 0.2), value: isMet)
    }
}
