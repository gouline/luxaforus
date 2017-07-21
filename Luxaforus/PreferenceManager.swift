//
//  PreferenceManager.swift
//  Luxaforus
//
//  Created by Mike Gouline on 21/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class PreferenceManager {
    
    private let userDefaults = UserDefaults.standard
    
    /// Fetches dimmed state.
    ///
    /// - Returns: True for dimmed, false otherwise.
    func fetchDimmed() -> Bool {
        return userDefaults.bool(forKey: "dimLight")
    }
    
    /// Persists dimmed state.
    ///
    /// - Parameter isDimmed: True for dimmed, false otherwise.
    func set(dimmed isDimmed: Bool) {
        userDefaults.set(isDimmed, forKey: "dimLight")
    }
    
}
