
//  Compass.swift
//  AppDevelopment

//  Created by Sofronie Albu on 13/05/2025.


import SwiftUI;
import CoreLocation;

struct TriangleCompass: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Define triangle pointing up
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))       // top
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))    // bottom left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))    // bottom right
        path.closeSubpath()
        
        return path
    }
}


struct Compass: View {
    @StateObject private var viewModel = CompassViewModel()
    @Environment(\.colorScheme) var colorScheme
    var diameter: CGFloat = 100;
    var standartSizeMultiplier: CGFloat = 0.01;

    
    var body: some View {
        let isDark = colorScheme == .dark
        let backgroundColor = isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.4)
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: diameter, height: diameter)

            VStack{
                    TriangleCompass()
                    .fill(Color.red)
                    .frame(width: (10  * standartSizeMultiplier
                                   * diameter ), height: 50 * standartSizeMultiplier * diameter)
                    .offset(y: (5 * standartSizeMultiplier) * diameter)

                TriangleCompass()
                    .fill(Color.white)
                    .frame(width: (10  * standartSizeMultiplier
                                   * diameter ), height: 50 * standartSizeMultiplier * diameter)
                    .rotationEffect(.degrees(180))
                    .offset(y: -(5 * standartSizeMultiplier) * diameter)
            }
            .rotationEffect(Angle(degrees: -viewModel.heading))
            
            
        }
        
    }
}

struct Compass_Previews: PreviewProvider {
    static var previews: some View {
        
            Compass()
                
    }
}
