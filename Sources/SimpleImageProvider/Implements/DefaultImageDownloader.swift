//
//  DefaultImageDownloader.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import Foundation

final class DefaultImageDownloader: ImageDownloader {
    
    func fetchImageData(url: String) async -> Data? {
        let url: URL = .init(string: url)!
        var urlRequest: URLRequest = .init(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("image/*", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                return data
            }
            return nil
        } catch {
            return nil
        }
    }
}
