import Testing
import UIKit
@testable import SimpleImageProvider

struct Cacher {
    
    init() {
        
        let fileManager: FileManager = .default
        
        let cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        let imageDirectoryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
        
        do {
            try fileManager.removeItem(atPath: imageDirectoryPath.path)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @Test func memoryCacherTesting() async throws {
        
        let memoryCacher = MemeoryCacher()
        
        let testUrl = "http://www.SimpleImageProvider/test/image.png"
        let emptyImage: UIImage = .init()
        
        let cachedImage1 = await memoryCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage1 == nil)
        
        memoryCacher.cacheImage(url: testUrl, size: nil, image: emptyImage)
        
        let cachedImage2 = await memoryCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage2 != nil)
    }


    @Test func diskCacherTest() async throws {
        
        let diskCacher = DiskCacher(diskCacheTracker: .init())
        
        let testUrl = "http://www.SimpleImageProvider/test/image.png"

        let testImage: UIImage = UIImage(systemName: "square.and.arrow.up")!
        
        let cachedImage1 = await diskCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage1 == nil)
        
        diskCacher.cacheImage(url: testUrl, size: nil, image: testImage)
        
        let cachedImage2 = await diskCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage2 != nil)
    }

    
    @Test func diskCacheOverflowTest() async throws {
        
        let maxFileCount = 10
        
        let diskCacheTracker = DefaultDiskCacheTracker(maxCount: maxFileCount)
        diskCacheTracker.clearStore()
        
        let diskCacher = DiskCacher(
            diskCacheTracker: diskCacheTracker,
            maxFileCount: maxFileCount,
            fileCountForDeleteWhenOverflow: 5
        )
        
        let rootUrl = "http://www.SimpleImageProvider/test/image"
        
        for index in 0..<15 {
            
            let url = rootUrl + "\(index)"
            let tempImage: UIImage = UIImage(systemName: "square.and.arrow.up")!
            
            diskCacher.cacheImage(url: url, size: nil, image: tempImage)
            
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        for deletedIndex in 0..<5 {
            
            let url = rootUrl + "\(deletedIndex)"
            let cachedImage = await diskCacher.requestImage(url: url, size: nil)
            
            #expect(cachedImage == nil)
        }
        
        for index in 10..<15 {
            
            let url = rootUrl + "\(index)"
            let cachedImage = await diskCacher.requestImage(url: url, size: nil)
            
            #expect(cachedImage != nil)
        }
    }
    
    @Test func concurrentDiskCacheTest() async throws {
        
        let maxFileCount = 50
        
        let diskCacheTracker = DefaultDiskCacheTracker(maxCount: maxFileCount)
        diskCacheTracker.clearStore()
        
        let diskCacher = DiskCacher(
            diskCacheTracker: diskCacheTracker,
            maxFileCount: maxFileCount,
            fileCountForDeleteWhenOverflow: 0
        )
        
        
        await withTaskGroup(of: Void.self) { group in
                
            for index in 0..<50 {
                group.addTask {
                    let url = "http://www.SimpleImageProvider/test/image\(index)"
                    let testImage: UIImage = UIImage(systemName: "square.and.arrow.up")!
                    
                    diskCacher.cacheImage(url: url, size: nil, image: testImage)
                }
            }
                
            // 모든 작업이 종료될 때까지 기다림
            await group.waitForAll()
        }
        
        await withTaskGroup(of: Void.self) { group in
            
            for index in 0..<50 {
                let url = "http://www.SimpleImageProvider/test/image\(index)"
                let cachedImage = await diskCacher.requestImage(url: url, size: nil)
                
                #expect(cachedImage != nil)
            }
        }
    }
}
