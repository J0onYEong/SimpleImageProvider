//
//  DiskCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import UIKit

final actor DiskCacher: ImageCacher {
    private let fileManager: FileManager = .init()
    
    private let maxFileCount: Int
    private let fileCountForDeleteWhenOverflow: Int
    
    private let diskCacheTracker: DefaultDiskCacheTracker
    
    
    init(
        diskCacheTracker: DefaultDiskCacheTracker,
        maxFileCount: Int,
        fileCountForDeleteWhenOverflow: Int
    ) {
        self.diskCacheTracker = diskCacheTracker
        self.maxFileCount = maxFileCount
        self.fileCountForDeleteWhenOverflow = fileCountForDeleteWhenOverflow
        
        createCacheDirectory()
    }
}


// MARK: ImageCacher
extension DiskCacher {
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        let key = createKey(url: url, size: size)
        guard let imageFilePath = createImagePath(key: key) else {
            return nil
        }
        let image = loadImage(path: imageFilePath.path)
        await diskCacheTracker.updateMember(id: key, value: .now)
        return image
    }
    
    func cacheImage(url: String, size: CGSize?, image: UIImage) async {
        let key = await createKey(url: url, size: size)
        await cacheImageFileToDisk(key: key, image: image)
    }
}


// MARK: File management
private extension DiskCacher {
    func createCacheDirectory() {
        guard var cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        cacheDictionaryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
        if !fileManager.fileExists(atPath: cacheDictionaryPath.path) {
            try? fileManager.createDirectory(at: cacheDictionaryPath, withIntermediateDirectories: true)
        }
    }

    func loadImage(path: String) -> UIImage? {
        guard let data = fileManager.contents(atPath: path) else {
            return nil
        }
        
        if let image = UIImage(data: data) {
            return image
        }
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
                    
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    func createImagePath(key: String) -> URL? {
        guard let cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let imageDirectoryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
        let imageFileName = createSafeFileName(draft: key)
        let imageFileURL = imageDirectoryPath
            .appendingPathComponent(imageFileName)
        return imageFileURL
    }
    
    func createSafeFileName(draft: String) -> String {
        let unsafeCharacters: [String] = [
            "/",":","?","=","&","%","#"," ","\"","'","<",">","\\","|","*",";"
        ]
        var safeFileName = draft
        
        // 각 특수 문자를 하이폰 문자로 변환
        for unsafe in unsafeCharacters {
            safeFileName = safeFileName.replacingOccurrences(of: unsafe, with: "-")
        }
        return safeFileName
    }
    
    
    func cacheImageFileToDisk(key: String, image: UIImage) async {
        guard let imageFilePath = createImagePath(key: key) else {
            return
        }
        if await diskCacheTracker.checkDiskIsFull() {
            // 이미지 파일 삭제
            let willRemoveList = await diskCacheTracker.loadOldestMembers(count: fileCountForDeleteWhenOverflow)
            for willRemoveKey in willRemoveList {
                guard let stringPath = createImagePath(key: willRemoveKey)?.path else {
                    continue
                }
                if fileManager.fileExists(atPath: stringPath) {
                    try? fileManager.removeItem(atPath: stringPath)
                    await diskCacheTracker.deleteMember(id: willRemoveKey)
                }
            }
        }
        
        // 공간확보후 이미지 파일 생성
        let imageFileCreationResult = fileManager.createFile(atPath: imageFilePath.path, contents: image.pngData())
        if imageFileCreationResult == true {
            await diskCacheTracker.createMember(id: key, value: .now)
        }
    }
}
