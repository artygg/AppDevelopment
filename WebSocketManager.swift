//
//  WebSocketManager.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 22/05/2025.
//

import Foundation

class WebSocketManager: ObservableObject {
    var webSocketTask: URLSessionWebSocketTask?

    func connect() {
        let url = URL(string: Config.webSocketURL)!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        listen()
    }

    func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received: \(text)")
                    // handle update here
                default:
                    break
                }
            }

            // Keep listening
            self?.listen()
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
