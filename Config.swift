//
//  Config.swift
//  AppDevelopment
//
//  Created by Timofei Arefev on 14/06/2025.
//

// Config.swift
import Foundation

struct Config {
    static let apiURLBaseString = "172.20.10.2:8080"
    static let webSocketURL = "ws://\(apiURLBaseString)/ws"
    static let apiURL = "http://\(apiURLBaseString)"
}
