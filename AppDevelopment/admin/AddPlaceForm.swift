//
//  AddPlaceForm.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 13/05/2025.
//

import SwiftUI
import Foundation

struct AddPlaceForm: View {
    let name: String
    var onCancel: () -> Void
    var onSave: (String, Int) -> Void

    @State private var draftName: String
    @State private var selectedCategoryIndex: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var categories: [Category] { allCategories }

    init(
        name: String,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String, Int) -> Void
    ) {
        self.name = name
        self.onCancel = onCancel
        self.onSave = onSave
        _draftName = State(initialValue: name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    nameInputSection
                    categorySelectionSection
                } header: {
                    sectionHeader
                }
                .listRowBackground(listRowBackgroundColor)
            }
            .scrollContentBackground(.hidden)
            .background(formBackgroundColor)
            .navigationTitle("Add New Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
        }
        .preferredColorScheme(nil)
    }
    
    // MARK: - View Components
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Place Name")
                .font(.headline)
                .foregroundColor(textColor)
            
            TextField("Enter place name", text: $draftName)
                .textFieldStyle(ThemedTextFieldStyle())
                .submitLabel(.done)
        }
        .padding(.vertical, 4)
    }
    
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.headline)
                .foregroundColor(textColor)
            
            categoryGrid
        }
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(0..<categories.count, id: \.self) { idx in
                CategorySelectionCard(
                    category: categories[idx],
                    isSelected: selectedCategoryIndex == idx,
                    action: {
                        selectedCategoryIndex = idx
                    }
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var sectionHeader: some View {
        Text("Place Details")
            .foregroundColor(colorScheme == .dark ? .white : .secondary)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            onCancel()
        }
        .foregroundColor(colorScheme == .dark ? .white : .blue)
    }
    
    private var saveButton: some View {
        Button("Save") {
            let chosenID = categories[selectedCategoryIndex].id
            onSave(draftName, chosenID)
        }
        .buttonStyle(ThemedSaveButtonStyle())
        .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // MARK: - Computed Properties
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var listRowBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white
    }
    
    private var formBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color(.systemGroupedBackground)
    }
}

// MARK: - Custom Styled Components

struct CategorySelectionCard: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var cardContent: some View {
        VStack(spacing: 8) {
            categoryIcon
            categoryText
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(12)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(color: shadowColor, radius: isSelected ? 4 : 0, x: 0, y: 2)
    }
    
    private var categoryIcon: some View {
        Image(systemName: category.iconName)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(iconColor)
    }
    
    private var categoryText: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
    }
    
    // MARK: - Color Computations
    
    private var iconColor: Color {
        if isSelected {
            return colorScheme == .dark ? .black : .white
        } else {
            return colorScheme == .dark ? .white : .primary
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return colorScheme == .dark ? .black : .white
        } else {
            return colorScheme == .dark ? .white : .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.yellow : Color.blue
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.yellow.opacity(0.8) : Color.blue.opacity(0.8)
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color.yellow.opacity(0.3) : Color.blue.opacity(0.3)
        } else {
            return Color.clear
        }
    }
}

struct ThemedTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        colorScheme == .dark ?
                        Color.gray.opacity(0.2) :
                        Color.gray.opacity(0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        colorScheme == .dark ?
                        Color.gray.opacity(0.4) :
                        Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

struct ThemedSaveButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(
                configuration.isPressed ?
                (colorScheme == .dark ? .black.opacity(0.8) : .white.opacity(0.8)) :
                (colorScheme == .dark ? .black : .white)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        configuration.isPressed ?
                        (colorScheme == .dark ? Color.yellow.opacity(0.8) : Color.blue.opacity(0.8)) :
                        (colorScheme == .dark ? Color.yellow : Color.blue)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview Support

#if DEBUG
struct AddPlaceForm_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            AddPlaceForm(
                name: "Sample Place",
                onCancel: {},
                onSave: { _, _ in }
            )
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            AddPlaceForm(
                name: "Sample Place",
                onCancel: {},
                onSave: { _, _ in }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}

// Mock data for preview (replace with your actual Category structure)
extension AddPlaceForm_Previews {
    static var mockCategories: [Category] {
        [
            Category(id: 1, displayName: "Restaurant", iconName: "fork.knife"),
            Category(id: 2, displayName: "Park", iconName: "tree"),
            Category(id: 3, displayName: "Shop", iconName: "bag"),
            Category(id: 4, displayName: "Gas Station", iconName: "fuelpump"),
        ]
    }
}
#endif
