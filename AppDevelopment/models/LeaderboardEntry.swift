//
//  LeaderboardEntry.swift
//  AppDevelopment
//
//  Created by M1stake Sequence on 2025-06-18.
//

import Foundation

struct LeaderboardEntry: Identifiable, Decodable, Equatable {
    let user:     String
    let captured: Int
    let rank:     Int
    var id: Int { rank }
}
