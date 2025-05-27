//
//  DecodedPlace.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-21.
//

import Foundation
import CoreLocation

struct DecodedPlace: Decodable, Identifiable {
    let name: String
    let coordinate: DecodedCoordinate
    let category_id: Int
    var isCaptured: Bool = false
    let id = UUID()

    enum CodingKeys: String, CodingKey {
        case name, coordinate, category_id
    }

    var clCoordinate: CLLocationCoordinate2D {
        .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct DecodedCoordinate: Decodable {
    let latitude: Double
    let longitude: Double
}
