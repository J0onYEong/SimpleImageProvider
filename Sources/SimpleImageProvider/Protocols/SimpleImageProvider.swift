// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

protocol SimpleImageProvider {
    
    func requestImage(url: String, size: CGSize) async -> UIImage
}
