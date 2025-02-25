//
//  LockedDictionary.swift
//  SimpleImageProvider
//
//  Created by choijunios on 2/5/25.
//

import Foundation

public final class LockedDictionary<Key, Value> where Key: Hashable {
    
    typealias Source = Dictionary<Key, Value>
    
    private var source: Source = [:]
    
    private let queue = DispatchQueue(
        label: "com.lockeddictionary.concurrentQueue",
        attributes: .concurrent
    )
    
    public var isEmpty: Bool {
        queue.sync { source.keys.isEmpty }
    }
    
    public init() { }
    
    public var dictionary: [Key: Value] {
        queue.sync { source }
    }
    
    public var values: [Value] {
        queue.sync { source.values.map({ $0 }) }
    }
    
    public var keys: [Key] {
        queue.sync { source.keys.map({ $0 }) }
    }
    
    public subscript(key: Key) -> Value? {
        get {
            queue.sync { source[key] }
        }
        set(newValue) {
            queue.async(flags: .barrier) { [weak self] in
                self?.source[key] = newValue
            }
        }
    }
    
    public func remove(key: Key) {
        queue.async(flags: .barrier) { [weak self] in
            self?.source.removeValue(forKey: key)
        }
    }
}
