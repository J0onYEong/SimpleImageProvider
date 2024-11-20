//
//  SimpleImageProvider.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

enum Config {
    static let presentLog = false
}

public final class SimpleImageProvider: @unchecked Sendable, SimpleImageProviderInterface {
    
    static let shared: SimpleImageProvider = .init()
    
    private let memoryCacher: ImageCacher
    private let diskCacher: ImageCacher
    private let imageDownloader: ImageDownloader
    private let imageModifier: ImageModifier
    
    init(
        memoryCacher: ImageCacher = MemeoryCacher(maxCacheCount: 50),
        diskCacher: ImageCacher = DiskCacher(
            diskCacheTracker: DefaultDiskCacheTracker(maxCount: 100),
            maxFileCount: 100,
            fileCountForDeleteWhenOverflow: 15
        ),
        imageDownloader: ImageDownloader = DefaultImageDownloader(),
        imageModifier: ImageModifier = DefaultImageModifier()
    ) {
        self.memoryCacher = memoryCacher
        self.diskCacher = diskCacher
        self.imageDownloader = imageDownloader
        self.imageModifier = imageModifier
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
                let downSampledImage = await imageModifier.downSamplingImage(dataBuffer: dataBuffer, size: size)
                
                log("이미지 다운 샘플링 완료")
                
                downloadedImage = downSampledImage
            } else {
                
                if let image = UIImage(data: dataBuffer) {
                    
                    downloadedImage = image
                    
                } else if let image = imageModifier.convertDataToUIImage(data: dataBuffer) {
                    
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
}

