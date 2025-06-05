//
//  CategoryIconView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import SwiftUI

struct CategoryIconView: View {
    let categoryID: Int
    let iconName: String

    var body: some View {
        Image(systemName: iconName)
            .font(.title)
    }
}
