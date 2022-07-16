//
//  WritableByIsolatedKeyPath.swift
//  CoinGecko
//
//  Created by Joshua Homann on 7/16/22.
//

import Foundation

protocol WritableByIsolatedKeyPath {
    @MainActor
    func set<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>,
        value: Value
    )
}

extension WritableByIsolatedKeyPath where Self: AnyObject {
    @MainActor
    func set<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>,
        value: Value
    ) {
        assert(Thread.isMainThread)
        self[keyPath: keyPath] = value
    }
}
