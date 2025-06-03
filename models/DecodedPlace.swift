//
//  DecodedPlace.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-05-21.
//

import Foundation
import CoreLocation
import SwiftUI

struct DecodedPlace: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let category_id: Int
    var captured: Bool
    let user_captured: String?
    
    // This property is NOT decoded from JSON, it's set manually in the ViewModel
    var iconName: String = "mappin.circle.fill"
    var iconColor: Color { captured ? .green : .blue }
    
    var clCoordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
    
    // CodingKeys does NOT include iconName
    private enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, category_id, captured, user_captured
    }
}
