//
//  DefaultDiskCacheTracker.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

import Foundation

class DefaultDiskCacheTracker: DiskCacheTracker {
   
    typealias Key = String
    typealias Value = Date
    
    private let maxCount: Int
    
    init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    private let source: UserDefaults = .init()
    private let dictKey = "DefaultDiskCacheTracker_dict"
    
    private lazy var currentDict: [Key: Value] = {
        
        if let dict = source.dictionary(forKey: dictKey) as? [Key: Value] {
            
            return dict
        }
        
        return [:]
    }()
    private let dictManagementQueue: DispatchQueue = .init(
        label: "com.DefaultDiskCacheTracker.dict",
        attributes: .concurrent
    )
    
    func requestCheckDiskIsFull() -> Bool {
        dictManagementQueue.sync {
            currentDict.keys.count >= maxCount
        }
    }
    
    func requestOldestMembers(count: Int) -> [String] {
        let sorted = currentDict.sorted { pair1, pair2 in
            pair1.value < pair2.value
        }
        
        if sorted.count <= count {
            
            return sorted.map({ $0.key })
        }
        
        return sorted[0..<count].map({ $0.key })
    }
    
    func requestCreateMember(id: String, value: Date) {
        dictManagementQueue.sync(flags: .barrier) {
            currentDict[id] = value
            saveCurrentDict()
        }
    }
    
    func requestReadMember(id: String) -> Date? {
        dictManagementQueue.sync {
            currentDict[id]
        }
    }
    
    func requestUpdateMember(id: String, value: Date) {
        dictManagementQueue.sync(flags: .barrier) {
            currentDict[id] = value
            saveCurrentDict()
        }
    }
    
    func requestDeleteMember(id: String) {
        dictManagementQueue.sync(flags: .barrier) {
            currentDict.removeValue(forKey: id)
            saveCurrentDict()
        }
    }
    
    private func saveCurrentDict() {
        source.set(currentDict, forKey: dictKey)
    }
}
