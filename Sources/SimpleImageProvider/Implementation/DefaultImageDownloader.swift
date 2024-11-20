//
//  DefaultImageDownloader.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import Foundation

final class DefaultImageDownloader: ImageDownloader {
    
    func requestImageData(url: String) async -> Data? {
        
        let url: URL = .init(string: url)!
        var urlRequest: URLRequest = .init(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("image/*", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                
                log("⬇️ 이미지 다운로드 완료")
                
                return data
            }
            
            return nil
            
        } catch {
            
            log("\(#function) 이미지 다운로드 요청 오류 \(error.localizedDescription)")
            
            return nil
        }
    }
}
