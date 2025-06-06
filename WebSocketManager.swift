//
//  WebSocketManager.swift
//  AppDevelopment
//
//  Created by Sofronie Albu on 22/05/2025.
//

import Foundation

class WebSocketManager: ObservableObject {
    var webSocketTask: URLSessionWebSocketTask?
    @Published var shouldRefreshPlaces = false

    func connect() {
        let url = URL(string: "ws://localhost:8080/ws")!
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
                    // Trigger update
                    DispatchQueue.main.async {
                        self?.shouldRefreshPlaces.toggle()
                    }
                default:
                    break
                }
            }

            self?.listen()
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
