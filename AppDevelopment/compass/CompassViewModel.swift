//
//  CompassViewModel.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 17/05/2025.
//

import Foundation
import CoreLocation
import SwiftUI
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

class CompassViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0.0
    
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.headingFilter = kCLHeadingFilterNone
        locationManager?.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.magneticHeading 
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
