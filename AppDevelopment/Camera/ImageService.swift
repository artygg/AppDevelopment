//
//  ImageService.swift
//  AppDevelopment
//
//  Created by Timofei Arefev on 16/06/2025.
//

import UIKit

struct ImageService {
    static func uploadImage(_ imageData: Data, fileName: String = "photo.jpg", placeID: Int = 1) {
        guard let url = URL(string: "\(Config.apiURL)/upload-file") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"place_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(placeID)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP response.")
                return
            }

            print("Upload finished with status: \(httpResponse.statusCode)")
        }.resume()
    }

    static func fetchImage(for placeID: Int, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: "\(Config.apiURL)/get-image?place_id=\(placeID)") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                print("Failed to load image:", error ?? "Unknown error")
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
