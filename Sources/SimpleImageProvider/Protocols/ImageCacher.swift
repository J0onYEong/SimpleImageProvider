//
//  ImageCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

protocol ImageCacher {
    
    func requestImage(url: String) async -> UIImage?
    
    func cacheImage(url: String, image: UIImage)
}
