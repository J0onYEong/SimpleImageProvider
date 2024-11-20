//
//  SimpleImageProvider.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

enum Config {
    static let presentLog = true
}

public final class SimpleImageProvider: SimpleImageProviderInterface {
    
    private let memoryCacher: ImageCacher
    private let diskCacher: ImageCacher
    private let imageDownloader: ImageDownloader
    
    init(
        memoryCacher: ImageCacher = MemeoryCacher(),
        diskCacher: ImageCacher = DiskCacher(),
        imageDownloader: ImageDownloader = DefaultImageDownloader()
    ) {
        self.memoryCacher = memoryCacher
        self.diskCacher = diskCacher
        self.imageDownloader = imageDownloader
    }
    
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
        // 메모리 캐싱 체크
        if let memoryCachedImage = await memoryCacher.requestImage(url: url, size: size) {
            
            log("메모리 캐싱 확인됨")
            
            return memoryCachedImage
        }
        
        // 디스크 캐싱 체크
        if let diskCachedImage = await diskCacher.requestImage(url: url, size: size) {
            
            log("디스크 캐싱 확인됨")
            
            defer {
                // 디스크에서 불러온 이미지를 메모리에 캐싱
                memoryCacher.cacheImage(url: url, size: size, image: diskCachedImage)
            }
                
            return diskCachedImage
        }
        
        
        // if 디스크 캐싱 확인 실패, 다운로드
        if let dataBuffer = await imageDownloader.requestImageData(url: url) {
            
            var downloadedImage: UIImage!
            
            // 이미지 다운 샘플링
            if let size {
                let downSampledImage = await downSampleImage(dataBuffer: dataBuffer, size: size)
                
                log("이미지 다운 샘플링 완료")
                
                downloadedImage = downSampledImage
            } else {
                
                if let image = UIImage(data: dataBuffer) {
                    
                    downloadedImage = image
                    
                } else if let image = convertDataToUIImage(data: dataBuffer) {
                    
                    // webp와 같은 미지원 타입
                    downloadedImage = image
                } else {
                    
                    return nil
                }
                
            }
            
            // 디스크, 메모리 캐싱에 등록
            [memoryCacher, diskCacher].forEach { cacher in
                
                cacher.cacheImage(url: url, size: size, image: downloadedImage)
            }
            
            return downloadedImage
        }
        
        return nil
    }
    
    private func downSampleImage(dataBuffer: Data, size: CGSize) async -> UIImage? {
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(dataBuffer as CFData, imageSourceOptions) else {
            
            return nil
        }
        
        let biggerLength = max(size.width, size.height)
        let scale = await UIScreen.main.scale
        let maxDimensionInPixels = biggerLength * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        let image = UIImage(cgImage: downsampledImage)
        
        return image
    }
    
    private func convertDataToUIImage(data: Data) -> UIImage? {
        
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
}

