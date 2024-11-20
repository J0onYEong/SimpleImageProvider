//
//  DefaultImageModifier.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

class DefaultImageModifier: ImageModifier {
    
    init() { }
    
    func convertDataToUIImage(data: Data) -> UIImage? {
        
        // CGImageSource를 생성
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            log("Failed to create image source")
            return nil
        }
        
        // CGImage 생성
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            log("Failed to create CGImage")
            return nil
        }
        
        // UIImage로 변환
        return UIImage(cgImage: cgImage)
    }
    
    func downSamplingImage(dataBuffer: Data, size: CGSize) async -> UIImage? {
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(dataBuffer as CFData, imageSourceOptions) else {
            
            return nil
        }
        
        let biggerLength = max(size.width, size.height)
        let scale = await UIScreen.main.scale
        let maxDimensionInPixels = biggerLength * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        let image = UIImage(cgImage: downsampledImage)
        
        return image
    }
}
