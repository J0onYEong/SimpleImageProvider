//
//  DiskCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

final class DiskCacher: @unchecked Sendable, ImageCacher {
    
    private let fileManager: FileManager = .init()
    private let concurrentQueue: DispatchQueue = .init(
        label: "com.DiskCacher",
        attributes: .concurrent
    )
    
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
    
    
    // MARK: public responsibility
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
        let key = createKey(url: url, size: size)
        
        guard let imageFilePath = createImagePath(key: key) else {
            log("\(#function) 이미지 경로 생성 실패")
            return nil
        }
        
        let image = getImage(path: imageFilePath.path)
        
        diskCacheTracker.requestUpdateMember(id: key, value: .now)
        
        return image
    }
    
    func cacheImage(url: String, size: CGSize?, image: UIImage) {
        
        let key = createKey(url: url, size: size)
        
        cacheImageFileToDisk(key: key, image: image)
    }
}

private extension DiskCacher {
    
    func createCacheDirectory() {
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
                
            guard let self else { return }
            
            guard var cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                
                fatalError()
            }
            
            cacheDictionaryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
            
            if !fileManager.fileExists(atPath: cacheDictionaryPath.path) {
                
                do {
                    
                    try fileManager.createDirectory(at: cacheDictionaryPath, withIntermediateDirectories: true)
                    
                } catch {
                    log("캐싱 디렉토리 생성실패 \(error.localizedDescription)")
                    fatalError()
                }
            }
        }
    }

    func getImage(path: String) -> UIImage? {
        
        concurrentQueue.sync {
            
            guard let data = fileManager.contents(atPath: path) else {
                
                return nil
            }
            
            
            if let image = UIImage(data: data) {
                
                return image
            }
            
            
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                log("이미지 소스 생성 실패")
                return nil
            }
            
            
            // CGImage 생성
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                log("이미지 생성 실패")
                return nil
            }
            
            
            return UIImage(cgImage: cgImage)
        }
    }
    
    func createImagePath(key: String) -> URL? {
        
        guard let cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            log("\(#function) \(key) 이미지 경로 생성 실패")
            return nil
        }
        
        let imageDirectoryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
        
        let imageFileName = createSafeFileName(draft: key)
        
        let imageFileURL = imageDirectoryPath
            .appendingPathComponent(imageFileName)
        
        return imageFileURL
    }
    
    
    func createSafeFileName(draft: String) -> String {
        
        let unsafeCharacters: [String: String] = [
            "/": "_",    // 슬래시 -> 언더바
            ":": "_",    // 콜론 -> 언더바
            "?": "_",    // 물음표 -> 언더바
            "=": "_",    // 등호 -> 언더바
            "&": "_",    // 앰퍼샌드 -> 언더바
            "%": "_",    // 퍼센트 -> 언더바
            "#": "_",    // 해시 -> 언더바
            " ": "_",    // 공백 -> 언더바
            "\"": "_",   // 쌍따옴표 -> 언더바
            "'": "_",    // 작은따옴표 -> 언더바
            "<": "_",    // 꺾쇠 -> 언더바
            ">": "_",    // 꺾쇠 -> 언더바
            "\\": "_",   // 역슬래시 -> 언더바
            "|": "_",    // 파이프 -> 언더바
            "*": "_",    // 별표 -> 언더바
            ";": "_",    // 세미콜론 -> 언더바
        ]

        var safeFileName = draft

        // 각 특수 문자를 안전한 문자로 변환
        for (unsafe, safe) in unsafeCharacters {
            safeFileName = safeFileName.replacingOccurrences(of: unsafe, with: safe)
        }

        return safeFileName
    }
    
    
    func cacheImageFileToDisk(key: String, image: UIImage) {
        
        guard let imageFilePath = createImagePath(key: key) else {
            log("\(#function) 이미지 경로 생성 실패")
            return
        }
            
        concurrentQueue.async(flags: .barrier) { @Sendable [weak self] in
            
            guard let self else { return }
            
            if diskCacheTracker.requestCheckDiskIsFull() {
                
                log("디스크 파일수가 \(maxFileCount)개를 초과하였음 삭제실행")
                
                // 이미지 파일 삭제
                
                let willRemoveList = diskCacheTracker.requestOldestMembers(
                    count: fileCountForDeleteWhenOverflow
                )
                
                
                willRemoveList.forEach { willRemoveKey in
                    
                    guard let stringPath = createImagePath(key: willRemoveKey)?.path else {
                        log("\(#function) 이미지 경로 생성 실패")
                        return
                    }
        
                    if fileManager.fileExists(atPath: stringPath) {
                        
                        do {
                            try fileManager.removeItem(atPath: stringPath)
                            diskCacheTracker.requestDeleteMember(id: willRemoveKey)
                            log("이미지 삭제 성공 \(stringPath)")
                        } catch {
                            log("\(stringPath) 이미지 삭제 실패 reason: \(error.localizedDescription)")
                        }
                    } else {
                        log("\(stringPath) 파일이 존재하지 않음")
                    }
                }
            }
            
            // 공간확보후 이미지 파일 생성
            
            let imageFileCreationResult = fileManager.createFile(atPath: imageFilePath.path, contents: image.pngData())
            
            if imageFileCreationResult == true {
                
                diskCacheTracker.requestCreateMember(id: key, value: .now)
            }
            log("디스크에 이미지 생성 \(imageFileCreationResult ? "성공" : "실패") 경로: \(imageFilePath)")
        }
    }
}
