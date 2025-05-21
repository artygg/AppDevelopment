//
//  Place.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 29/04/2025.
//

import CoreLocation

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let placeIcon: String
    var isCaptured: Bool = false
}
