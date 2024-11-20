//
//  DiskCacheTracker.swift
//  SimpleImageProvider
//
//  Created by choijunios on 11/20/24.
//

protocol DiskCacheTracker {
    
    associatedtype Key: Hashable
    associatedtype Value
    
    func clearStore()
    
    func requestCheckDiskIsFull() -> Bool
    
    func requestOldestMembers(count: Int) -> [Key]
    
    func requestCreateMember(id: Key, value: Value)
    func requestReadMember(id: Key) -> Value?
    func requestUpdateMember(id: Key, value: Value)
    func requestDeleteMember(id: Key)
}
