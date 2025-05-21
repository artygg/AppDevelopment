//
//  AddPlaceForm.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 13/05/2025.
//
import SwiftUI


struct AddPlaceForm: View {
  let name: String              // plain String
  var onCancel: () -> Void
  var onSave: (String) -> Void  // give back the edited text

  @State private var draftName: String

  init(name: String,
       onCancel: @escaping () -> Void,
       onSave: @escaping (String) -> Void) {
    self.name = name
    self.onCancel = onCancel
    self.onSave = onSave
    _draftName = State(initialValue: name)
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField("Place name", text: $draftName)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { onSave(draftName) }
        }
      }
    }
  }
}
