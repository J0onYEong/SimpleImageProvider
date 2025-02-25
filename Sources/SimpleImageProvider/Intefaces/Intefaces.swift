//
//  Intefaces.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import UIKit
import Combine

// MARK: ImageProvider
public protocol ImageProvider {
    func requestImage(url: String, size: CGSize?) -> AnyPublisher<UIImage?, Never>
    func requestImage(url: String, size: CGSize?) async -> UIImage?
}


// MARK: ImageDownloader
public protocol ImageDownloader {
    func fetchImageData(url: String) async -> Data?
}


// MARK: ImageCacher
public protocol ImageCacher {
    func requestImage(url: String, size: CGSize?) async -> UIImage?
    func cacheImage(url: String, size: CGSize?, image: UIImage)
}


// MARK: DiskCacheTracker
public protocol CacheTracker {
    associatedtype Key: Hashable
    associatedtype Value
    func clearStore()
    func checkDiskIsFull() -> Bool
    func loadOldestMembers(count: Int) -> [Key]
    func createMember(id: Key, value: Value)
    func loadMember(id: Key) -> Value?
    func updateMember(id: Key, value: Value)
    func deleteMember(id: Key)
}


// MARK: ImageModifier
public protocol ImageModifier {
    func downSamplingImage(dataBuffer: Data, size: CGSize) async -> UIImage?
    func convertDataToUIImage(data: Data) -> UIImage?
}
