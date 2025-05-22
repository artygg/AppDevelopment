//
//  DecodedPlace.swift
//  AppDevelopment
//
//  Created by Ekaterina Tarlykova on 2025-05-21.
//

import Foundation

struct DecodedPlace: Decodable, Identifiable {
    let id = UUID()
    let name: String
    let coordinate: DecodedCoordinate
    let category_id: Int
}

struct DecodedCoordinate: Decodable {
    let latitude: Double
    let longitude: Double
}
