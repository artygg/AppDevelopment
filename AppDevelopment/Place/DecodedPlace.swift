import Foundation
import CoreLocation
import SwiftUI

struct DecodedPlace: Identifiable, Codable {
    let id:          Int
    let name:        String
    let latitude:    Double
    let longitude:   Double
    let category_id: Int
    var captured:    Bool
    var user_captured: String?
    var cooldown_until: Date?

    var iconName: String = "mappin.circle.fill"

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, category_id,
             captured, user_captured, cooldown_until
    }

    var clCoordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    func iconColor(for user: String) -> Color {
        if captured {
            return user_captured == user ? .green : .red
        }
        if let cd = cooldown_until, cd > Date() { return .gray }
        return .blue
    }
}
