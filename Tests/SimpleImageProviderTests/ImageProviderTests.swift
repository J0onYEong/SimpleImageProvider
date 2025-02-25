//
//  ImageProviderTests.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import UIKit
import Testing
import Combine

@testable import SimpleImageProvider

struct ImageProviderTests {
    
    /// 테스트 목적: 다중 쓰레드 환경에서 디스크 캐시접속시 동시성문제가 발생하는지 확인한다.
    @Test
    func checkConcurrentDiskCaching() async {
        //Given
        let maxFileCount = 50
        let diskCacheTracker = DefaultDiskCacheTracker(maxCount: maxFileCount)
        await diskCacheTracker.clearStore()
        let diskCacher = DiskCacher(
            diskCacheTracker: diskCacheTracker,
            maxFileCount: maxFileCount,
            fileCountForDeleteWhenOverflow: 5
        )
        let baseURLForKey = "www.test"
        
        
        // When
        // - 50(=maxFileCount)개의 이미지 캐싱이 동시에 발생
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<maxFileCount {
                group.addTask {
                    let testURL = "\(baseURLForKey)/\(index)"
                    // 실제이미지를 사용하지 않고 시스템 이미지를 사용한다.
                    let testImage = UIImage(systemName: "square.and.arrow.up")!
                    await diskCacher.cacheImage(url: testURL, size: nil, image: testImage)
                }
            }
            await group.waitForAll()
        }
        
        
        // Then
        // - 50개의 이미지가 모두 디스캐싱이 이루어졌는지 확인한다.
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                let testURL = "\(baseURLForKey)/\(index)"
                let cachedImage = await diskCacher.requestImage(url: testURL, size: nil)
                #expect(cachedImage != nil)
            }
        }
    }
    
    
    /// 테스트 목적: 디스크 캐시의 LRU기능이 정상적으로 동작하는지 확인한다.
    @Test
    func checkDiskCacheLRUFunction() async throws {
        // Given
        let maxFileCount = 10
        let diskCacheTracker = DefaultDiskCacheTracker(maxCount: maxFileCount)
        await diskCacheTracker.clearStore()
        let diskCacher = DiskCacher(
            diskCacheTracker: diskCacheTracker,
            maxFileCount: maxFileCount,
            fileCountForDeleteWhenOverflow: 5
        )
        let baseURLForKey = "www.test"
        
        
        // When
        // - 15개의 파일이 1초간격 순차적으로 저장(LRU를 보장하기 위한 인위적 조치)
        for index in 0..<15 {
            let url = "\(baseURLForKey)/\(index)"
            let tempImage: UIImage = UIImage(systemName: "square.and.arrow.up")!
            await diskCacher.cacheImage(url: url, size: nil, image: tempImage)
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        
        //Then
        // - 최초 5개의 이미지는 디스크에서 제거된다.
        for deletedIndex in 0..<5 {
            let url = "\(baseURLForKey)/\(deletedIndex)"
            let cachedImage = await diskCacher.requestImage(url: url, size: nil)
            #expect(cachedImage == nil)
        }
        // - 뒤에서 10개의 파일은 LRU에 의해 디스크에 유지된다.
        for index in 10..<15 {
            let url = "\(baseURLForKey)/\(index)"
            let cachedImage = await diskCacher.requestImage(url: url, size: nil)
            #expect(cachedImage != nil)
        }
    }
}
