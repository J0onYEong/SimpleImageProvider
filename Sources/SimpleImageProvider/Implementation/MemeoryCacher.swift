//
//  MemeoryCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

class MemeoryCacher: ImageCacher {
    
    private let cache: NSCache<NSString, UIImage> = .init()
    
    init() {
        cache.countLimit = 20
    }
    
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
        let key: NSString = .init(string: createKey(url: url, size: size))
        
        return cache.object(forKey: key)
    }
    
    func cacheImage(url: String, size: CGSize?, image: UIImage) {
        
        let key: NSString = .init(string: createKey(url: url, size: size))
        
        cache.setObject(image, forKey: key)
    }
}
