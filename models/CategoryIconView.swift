//
//  CategoryIconView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import SwiftUI
import UIKit

struct CategoryIconView: View {
    let categoryID: Int
    let iconName: String

    private var resolvedName: String {
        UIImage(systemName: iconName) == nil ? "questionmark.circle" : iconName
    }

    var body: some View {
        Image(systemName: resolvedName)
            .font(.title)
    }
}
