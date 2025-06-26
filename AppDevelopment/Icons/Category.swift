//
//  Category.swift
//  AppDevelopment
//
//  Created by Artyom Grishayev on 05/06/2025.
//


import Foundation


struct Category {
    let id:          Int
    let displayName: String
    let iconName:    String
}

let allCategories: [Category] = [
    Category(id: 1,  displayName: "Park",               iconName: "leaf.circle.fill"),
    Category(id: 2,  displayName: "Museum",             iconName: "building.columns.fill"),
    Category(id: 3,  displayName: "Restaurant",         iconName: "fork.knife.circle.fill"),
    Category(id: 4,  displayName: "Landmark",           iconName: "mappin.circle.fill"),
    Category(id: 5,  displayName: "Cafe/Bar",           iconName: "wineglass.fill"),
    Category(id: 6,  displayName: "Theater",            iconName: "theatermasks.fill"),
    Category(id: 7,  displayName: "Beach",              iconName: "beach.umbrella.fill"),
    Category(id: 8,  displayName: "Hotel",              iconName: "building.2.fill"),
    Category(id: 9,  displayName: "Shopping",           iconName: "cart.fill"),
    Category(id: 10, displayName: "Hospital/First Aid", iconName: "cross.case.fill")
]
