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
        
        let memoryCacher = DiskCacher()
        
        let testUrl = "http://www.SimpleImageProvider/test/image.png"

        let testImage: UIImage = UIImage(systemName: "square.and.arrow.up")!
        
        let cachedImage1 = await memoryCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage1 == nil)
        
        memoryCacher.cacheImage(url: testUrl, size: nil, image: testImage)
        
        let cachedImage2 = await memoryCacher.requestImage(url: testUrl, size: nil)
        
        #expect(cachedImage2 != nil)
    }

}
