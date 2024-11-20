//
//  DiskCacher.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import UIKit

final class DiskCacher: ImageCacher {
    
    private let fileManager: FileManager = .init()
    private let serialQueue: DispatchQueue = .init(
        label: "com.DiskCacher",
        attributes: .concurrent
    )
    
    private let maxFileCount: Int = 30
    
    // MARK: public responsibility
    func requestImage(url: String, size: CGSize?) async -> UIImage? {
        
        let key = createKey(url: url, size: size)
        
        guard let imageFilePath = createImagePath(key: key) else {
            log("\(#function) 이미지 경로 생성 실패")
            return nil
        }
        
        let image = getImage(path: imageFilePath.path)
        
        return image
    }
    
    func cacheImage(url: String, size: CGSize?, image: UIImage) {
        
        let key = createKey(url: url, size: size)
        
        guard let imageFilePath = createImagePath(key: key) else {
            log("\(#function) 이미지 경로 생성 실패")
            return
        }
    }
}

extension DiskCacher {

    func getImage(path: String) -> UIImage? {
        
        serialQueue.sync {
            
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
        
        serialQueue.sync(flags: .barrier) {
            
            guard let cacheDictionaryPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                log("\(#function) \(key) 이미지 경로 생성 실패")
                return nil
            }
            
            let imageDirectoryPath = cacheDictionaryPath.appendingPathComponent("CachedDiskImage")
            
            if !fileManager.fileExists(atPath: imageDirectoryPath.path) {
                    
                // 이미지 캐싱 딕셔너리가 없는 경우 딕셔너리를 생성
                
                do {
                    try fileManager
                        .createDirectory(
                            at: imageDirectoryPath,
                            withIntermediateDirectories: true
                        )
                } catch {
                    log("\(#function) 이미지 캐싱 디렉토리 생성 실패 \(error.localizedDescription)")
                    return nil
                }
            }
            
            let imageFileURL = imageDirectoryPath
                .appendingPathComponent(createSafeFileName(draft: key))
            
            return imageFileURL
        }
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
}
