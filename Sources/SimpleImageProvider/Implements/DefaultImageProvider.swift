//
//  DefaultImageProvider.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import UIKit
import Combine

final class DefaultImageProvider: ImageProvider {
    
    // Dependency
    private var memoryCacher: ImageCacher
    private var diskCacher: ImageCacher
    private let imageDownloader: ImageDownloader
    private let imageModifier: ImageModifier
    
    
    // Singleton
    static let shared: DefaultImageProvider = .init(
        memoryCacher: DefaultMemeoryCacher(maxCacheCount: 50),
        diskCacher: DefaultDiskCacher(
            diskCacheTracker: DefaultDiskCacheTracker(maxCount: 100),
            maxFileCount: 100,
            fileCountForDeleteWhenOverflow: 15
        ),
        imageDownloader: DefaultImageDownloader(),
        imageModifier: DefaultImageModifier()
    )
    
    private init(
        memoryCacher: ImageCacher,
        diskCacher: ImageCacher,
        imageDownloader: ImageDownloader,
        imageModifier: ImageModifier
    ) {
        self.memoryCacher = memoryCacher
        self.diskCacher = diskCacher
        self.imageDownloader = imageDownloader
        self.imageModifier = imageModifier
    }
}


// MARK: ImageProvider
extension DefaultImageProvider {
    func requestImage(url: String, size: CGSize?) -> AnyPublisher<UIImage?, Never> {
        Future { promise in
            Task { [weak self] in
                guard let self else { return }
                let image = await requestImage(url: url, size: size)
                promise(.success(image))
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
        // 메모리 캐싱 체크
        if let memoryCachedImage = await memoryCacher.requestImage(url: url, size: size) {
            return memoryCachedImage
        }
        // 디스크 캐싱 체크
        if let diskCachedImage = await diskCacher.requestImage(url: url, size: size) {
            defer {
                // 디스크 정보를 메모리에 캐싱
                memoryCacher.cacheImage(url: url, size: size, image: diskCachedImage)
            }
            return diskCachedImage
        }
        
        // 디스크 캐싱 정보가 없는 경우 다운로드 수행
        if let dataBuffer = await imageDownloader.fetchImageData(url: url) {
            var downloadedImage: UIImage!
            // 이미지 다운 샘플링
            if let size {
                let downSampledImage = await imageModifier.downSamplingImage(dataBuffer: dataBuffer, size: size)
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
            
            // 다운로드한 이미지를 디스크, 메모리 캐싱에 등록
            [memoryCacher, diskCacher].forEach { cacher in
                cacher.cacheImage(url: url, size: size, image: downloadedImage)
            }
            return downloadedImage
        }
        return nil
    }
}
