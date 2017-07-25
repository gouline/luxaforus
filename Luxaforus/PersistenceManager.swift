//
//  PersistenceManager.swift
//  Luxaforus
//
//  Created by Mike Gouline on 21/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa
import KeychainSwift

private let kKeychainPrefix = "Luxaforus"

private let kKeyDimmed = "dimLight"

private let kKeySlackToken = "\(kKeychainPrefix)-SlackToken"

class PersistenceManager {
    
    private let defaults = UserDefaults.standard
    private let keychain = KeychainSwift()
    
    /// Fetches dimmed state.
    ///
    /// - Returns: True for dimmed, false otherwise.
    func fetchDimmed() -> Bool {
        return defaults.bool(forKey: kKeyDimmed)
    }
    
    /// Persists dimmed state.
    ///
    /// - Parameter isDimmed: True for dimmed, false otherwise.
    func set(dimmed isDimmed: Bool) {
        defaults.set(isDimmed, forKey: kKeyDimmed)
    }
    
    /// Fetches Slack token.
    ///
    /// - Returns: Current Slack token or null.
    func fetchSlackToken() -> String? {
        return keychain.get(kKeySlackToken)
    }
    
    /// Persists Slack token.
    ///
    /// - Parameter token: Current Slack token or null.
    func set(slackToken token: String?) {
        if token != nil {
            keychain.set(token!, forKey: kKeySlackToken)
        } else {
            keychain.delete(kKeySlackToken)
        }
    }
    
}
