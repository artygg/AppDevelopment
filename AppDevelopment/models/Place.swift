//
//  Place.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-05.
//

import CoreLocation

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let placeIcon: String
    var isCaptured: Bool = false
    var user_captured: String?
}
