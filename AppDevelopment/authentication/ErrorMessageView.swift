//
//  ErrorMessageView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 24/06/2025.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal, 32)
            .multilineTextAlignment(.center)
    }
}
