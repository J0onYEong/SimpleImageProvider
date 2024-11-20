//
//  ImageDownloader.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import Foundation

protocol ImageDownloader {
    
    func requestImageData(url: String) async -> Data?
}
