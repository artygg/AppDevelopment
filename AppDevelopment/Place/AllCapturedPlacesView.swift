//
//  AllCapturedPlacesView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 20/06/2025.
//

import SwiftUI

struct AllCapturedPlacesView: View {
    @ObservedObject var profileVM : ProfileViewModel
    @ObservedObject var placesVM  : DecodedPlacesViewModel
    let capturedPlaces: [Place]

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss)     private var dismiss
    @State private var search   = ""

    private var bg: some View {
        LinearGradient(colors: scheme == .dark ? [.black, .indigo] : [.white, .blue.opacity(0.25)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }

    private var filtered: [Place] {
        search.isEmpty
        ? capturedPlaces
        : capturedPlaces.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                if filtered.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { place in
                                PlaceCard(place: place)
                                    .onTapGesture {
                                        Task { await profileVM.loadOwnerQuiz(for: place,
                                                                             in: placesVM) }
                                    }
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8).padding(.bottom, 20)
                    }
                }
            }
            .background(bg)
            .navigationTitle("Captured Places")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $search, prompt: "Search…")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done", action: dismiss.callAsFunction) } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(capturedPlaces.count)").font(.largeTitle.weight(.bold))
            Text("Total Captured").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24).padding(.vertical, 16)
        .background(Material.ultraThin, in: Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash").font(.system(size: 50))
            Text(search.isEmpty ? "No captured places yet" : "Nothing found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
