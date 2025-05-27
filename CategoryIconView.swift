//
//  CategoryIconView.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-22.
//

import SwiftUI

struct CategoryIconView: View {
    let categoryID: Int
    let mapping: [String: String]

    var body: some View {
        let iconName = mapping["\(categoryID)"] ?? "mappin.circle.fill"
        Image(systemName: iconName).font(.title)
    }
}
