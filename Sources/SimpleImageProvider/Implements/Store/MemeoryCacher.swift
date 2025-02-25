//
//  MemeoryCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import UIKit

final class MemeoryCacher: ImageCacher {
    // NSCache store
    private let cache: NSCache<NSString, UIImage> = .init()
    
    init(maxCacheCount: Int) {
        cache.countLimit = maxCacheCount
    }
}


// MARK: ImageCacher
extension MemeoryCacher {
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        let key: NSString = .init(string: createKey(url: url, size: size))
        return cache.object(forKey: key)
    }
    
    func cacheImage(url: String, size: CGSize?, image: UIImage) {
        let key: NSString = .init(string: createKey(url: url, size: size))
        cache.setObject(image, forKey: key)
    }
}
