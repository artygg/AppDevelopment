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
                Section("Place Details") {
                    TextField("Place name", text: $draftName)

                    Picker("Category", selection: $selectedCategoryIndex) {
                        ForEach(0..<categories.count, id: \.self) { idx in
                            Text(categories[idx].displayName)
                                .tag(idx)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let chosenID = categories[selectedCategoryIndex].id
                        onSave(draftName, chosenID)
                    }
                }
            }
        }
    }
}
