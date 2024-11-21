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
    
    public static let shared: SimpleImageProvider = .init()
    
    private var memoryCacher: ImageCacher
    private var diskCacher: ImageCacher
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
    
    
    /// 이 메서드는 캐시 설정을 구성합니다.
    /// - Note: 해당 메서드는 **앱이 런칭된 이후에 사용하지 않기를 권장합니다.**
    ///         런타임 중 호출할 경우, 예상치 못한 동작이 발생할 수 있습니다.
    /// - Parameters:
    ///   - maxCacheImageCount: 메모리 캐시에 저장할 최대 이미지 수.
    ///   - maxDiskImageCount: 디스크 캐시에 저장할 최대 이미지 수.
    ///   - percentToDeleteWhenDiskOverflow: 디스크 캐시 초과 시 삭제할 비율 (0.0 ~ 1.0).
    public func requestConfigureState(
        maxCacheImageCount: Int,
        maxDiskImageCount: Int,
        percentToDeleteWhenDiskOverflow: Float
    ) {
        
        self.memoryCacher = MemeoryCacher(maxCacheCount: maxCacheImageCount)
            
        let deleteFileCountWhenOverflow = Int(
            (percentToDeleteWhenDiskOverflow / 100) * Float(maxDiskImageCount)
        )
        
        diskCacher = DiskCacher(
            diskCacheTracker: DefaultDiskCacheTracker(maxCount: maxDiskImageCount),
            maxFileCount: maxDiskImageCount,
            fileCountForDeleteWhenOverflow: deleteFileCountWhenOverflow
        )
    }
    
    
    /// 이 메서드는 이미지를 로드합니다.
    /// - Note: URL을 통해 이미지를 비동기로 로드하며, 지정된 사이즈로 다운 샘플링할 수 있습니다.
    ///         이미지 로드 작업은 비동기적으로 수행되며, 네트워크 연결 상태에 따라 실패할 수 있습니다.
    /// - Parameters:
    ///   - url: 로드할 이미지의 URL.
    ///   - size: 다운 샘플링할 이미지의 사이즈. `nil`인 경우 원본 크기로 로드됩니다.
    /// - Returns: 성공 시 `UIImage` 객체를 반환하고, 실패 시 `nil`을 반환합니다.
    public func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
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

