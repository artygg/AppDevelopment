//
//  AllCapturedPlacesView.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 20/06/2025.
//

import SwiftUI
import CoreLocation

struct AllCapturedPlacesView: View {
    let capturedPlaces: [Place]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredPlaces: [Place] {
        if searchText.isEmpty {
            return capturedPlaces
        } else {
            return capturedPlaces.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(capturedPlaces.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Places Captured")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(filteredPlaces.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Text("Showing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    Divider()
                }
                .background(Color(.systemGroupedBackground))
                
                if filteredPlaces.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: searchText.isEmpty ? "mappin.slash" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No places captured yet" : "No places found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Text("Try adjusting your search terms")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPlaces) { place in
                                PlaceCard(place: place)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("All Places")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search places...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}
