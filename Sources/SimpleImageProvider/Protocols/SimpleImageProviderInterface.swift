// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

protocol SimpleImageProviderInterface {
    
    func requestImage(url: String, size: CGSize?) async -> UIImage?
    
    
    func requestConfigureState(
        maxCacheImageCount: Int,
        maxDiskImageCount: Int,
        percentToDeleteWhenDiskOverflow: Float
    )
}
