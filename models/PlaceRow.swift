//
//  PlaceRow.swift
//  AppDevelopment
//
//  Created by Timofei Arefev on 16/06/2025.
//
import SwiftUI

struct PlaceRow: View {
    let place: DecodedPlace

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: place.iconName)
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            Text(place.name)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}
