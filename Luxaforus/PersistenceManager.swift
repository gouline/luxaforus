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
private let kKeyIgnoreUpdates = "ignoreUpdates"
private let kKeyLatestUpdate = "latestUpdate"

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
    
    /// Fetches disable updates state.
    ///
    /// - Returns: True to ignore updates, false otherwise.
    func fetchIgnoreUpdates() -> Bool {
        return defaults.bool(forKey: kKeyIgnoreUpdates)
    }
    
    /// Persists ignore updates state.
    ///
    /// - Parameter isDisabled: True to ignore updates, false otherwise.
    func set(ignoreUpdates isDisabled: Bool) {
        defaults.set(isDisabled, forKey: kKeyIgnoreUpdates)
    }
    
    /// Fetches latest update version.
    ///
    /// - Returns: Latest update version or nil.
    func fetchLatestUpdate() -> String? {
        return defaults.string(forKey: kKeyLatestUpdate)
    }
    
    /// Persists latest update version.
    ///
    /// - Parameter update: Latest update version.
    func set(latestUpdate update: String?) {
        defaults.set(update, forKey: kKeyLatestUpdate)
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
        if let token = token {
            keychain.set(token, forKey: kKeySlackToken)
        } else {
            keychain.delete(kKeySlackToken)
        }
    }
    
}
