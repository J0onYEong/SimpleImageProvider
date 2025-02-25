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
    func cacheImage(url: String, size: CGSize?, image: UIImage) async
}


// MARK: DiskCacheTracker
public protocol CacheTracker {
    associatedtype Key: Hashable
    associatedtype Value
    func clearStore() async
    func checkDiskIsFull() async -> Bool
    func loadOldestMembers(count: Int) async -> [Key]
    func createMember(id: Key, value: Value) async
    func loadMember(id: Key) async -> Value?
    func updateMember(id: Key, value: Value) async
    func deleteMember(id: Key) async
}


// MARK: ImageModifier
public protocol ImageModifier {
    func downSamplingImage(dataBuffer: Data, size: CGSize) async -> UIImage?
    func convertDataToUIImage(data: Data) -> UIImage?
}
