//
//  AdminMapView.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 13/05/2025.
//
import SwiftUI
import MapKit
import CoreLocation

struct AdminMapView: View {
  @Binding var places: [Place]
  @Binding var region: MapCameraPosition
  @State private var currentCenter = CLLocationCoordinate2D(latitude: 52.78, longitude: 6.90)
  let isAdmin: Bool

  @State private var isEditing = false
  @State private var showingAddSheet = false
  @State private var newPlaceName = ""
  @State private var newPlaceCoord: CLLocationCoordinate2D?

  var body: some View {
    ZStack {
        Map(position: $region) {
            ForEach(places) { place in
              Marker(place.name, coordinate: place.coordinate)
                .tint(place.isCaptured ? .green : .blue)
            }
            UserAnnotation()
          }
          .onMapCameraChange(frequency: .onEnd) { context in
            currentCenter = context.region.center
          }
          .ignoresSafeArea()
        
        if isEditing {
            Image(systemName: "mappin.circle.fill")
              .font(.system(size: 44))
              .foregroundColor(.red)
              .offset(y: -22)
            
            
            VStack {
                  Spacer()
                  HStack {
                    Spacer()
                    Button("Add Place") {
                        newPlaceCoord = currentCenter
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    Spacer()
                  }
                }
            
          }
        
        VStack {
          Spacer()
          HStack {
            Button { isEditing.toggle() } label: {
              Image(systemName: isEditing ? "xmark.circle" : "plus.circle")
                .font(.largeTitle)
                .padding()
            }
            Spacer()
          }
        }
    }
    .sheet(isPresented: $showingAddSheet) {
      AddPlaceForm(
        name: newPlaceName,
        onCancel: {
          showingAddSheet = false
          isEditing = false
        },
        onSave: { finalName in
          if let coord = newPlaceCoord, !finalName.isEmpty {
            places.append(
              Place(
                name: finalName,
                coordinate: coord,
                placeIcon: "mappin.circle"
              )
            )
          }
          showingAddSheet = false
          isEditing = false
        }
      )
    }

  }
}
