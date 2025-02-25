//
//  DefaultDiskCacheTracker.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/7/25.
//

import Foundation

final class DefaultDiskCacheTracker: DiskCacheTracker {
    typealias Key = String
    typealias Value = Date
    
    // State
    private let maxCount: Int
    
    
    // Check store
    private let source: UserDefaults = .init()
    private let dictKey = "DefaultDiskCacheTracker_dict"
    private let diskCacheInfo: LockedDictionary<Key, Value> = .init()
    
    
    init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    private func saveCurrentDict() {
        source.set(diskCacheInfo.dictionary, forKey: dictKey)
    }
}


// MARK: DiskCacheTracker
extension DefaultDiskCacheTracker {
    func clearStore() {
        source.removeObject(forKey: dictKey)
    }
    
    func checkDiskIsFull() -> Bool {
        diskCacheInfo.keys.count >= maxCount
    }
    
    func loadOldestMembers(count: Int) -> [String] {
        let sortedInfo = diskCacheInfo.dictionary.sorted { $0.value < $1.value }
        if sortedInfo.count <= count {
            return sortedInfo.map({ $0.key })
        }
        return sortedInfo[0..<count].map({ $0.key })
    }
    
    func createMember(id: String, value: Date) {
        diskCacheInfo[id] = value
        saveCurrentDict()
    }
    
    func loadMember(id: String) -> Date? {
        return diskCacheInfo[id]
    }
    
    func updateMember(id: String, value: Date) {
        diskCacheInfo[id] = value
        saveCurrentDict()
    }
    
    func deleteMember(id: String) {
        diskCacheInfo.remove(key: id)
        saveCurrentDict()
    }
}
