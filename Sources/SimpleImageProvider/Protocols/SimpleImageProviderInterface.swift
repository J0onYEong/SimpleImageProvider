// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

protocol SimpleImageProviderInterface {
    
    func requestImage(url: String, size: CGSize?) async -> UIImage
}
