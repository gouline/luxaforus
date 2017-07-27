//
//  UpdateController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 27/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

class UpdateController {
    
    private let notificationManager: NotificationManager
    private let persistenceManager: PersistenceManager
    
    private var checkInProgress = false
    
    init(notificationManager: NotificationManager, persistenceManager: PersistenceManager) {
        self.notificationManager = notificationManager
        self.persistenceManager = persistenceManager
    }
    
    /// Checks for updates.
    ///
    /// - Parameter automatic: True if automatic check, false if manual.
    func check(automatic: Bool) {
        guard !checkInProgress && (!automatic || !persistenceManager.fetchIgnoreUpdates()) else {
            return
        }
        
        checkInProgress = true
        
        _ = Alamofire.request("https://api.github.com/repos/traversals/luxaforus/releases/latest").responseJSON { response in
            var updateSuccess = false
            
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let version = json["tag_name"].string, let url = json["html_url"].string {
                    if self.offerLatestRelease(automatic: automatic, version: version, url: url) {
                        updateSuccess = true
                        
                        let latest = self.sanitize(version: version)
                        let messageText = "Update Available"
                        let informationalText = "Latest version \(latest) is available."
                        
                        if automatic {
                            // Automatic checks raise notifications
                            let notification = NSUserNotification()
                            notification.title = messageText
                            notification.informativeText = informationalText
                            notification.identifier = "update-\(version)"
                            self.notificationManager.deliver(notification, activateCallback: { notification in
                                self.downloadUpdate(withUrl: url)
                                return true
                            })
                        } else {
                            // Manual checks raise alerts
                            let alert = NSAlert()
                            alert.messageText = messageText
                            alert.informativeText = informationalText
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: "Download")
                            alert.addButton(withTitle: "Cancel")
                            if alert.runModal() == NSAlertFirstButtonReturn {
                                self.downloadUpdate(withUrl: url)
                            }
                        }
                    }
                }
            case .failure(_):
                NSLog("Update: releases/latest failure")
            }
            
            if !updateSuccess && !automatic {
                // Only manual checks raise no-update alerts
                let alert = NSAlert()
                alert.messageText = "No Updates Available"
                alert.informativeText = "You are running the latest version."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            
            self.checkInProgress = false
        }
    }
    
    // MARK: - Internal
    
    /// Offers latest release for update.
    ///
    /// - Parameters:
    ///   - automatic: True if automatic check, false if manual.
    ///   - version: Latest version offered.
    ///   - url: Download URL for latest version.
    /// - Returns: True if offer accepted, false otherwise.
    private func offerLatestRelease(automatic: Bool, version: String, url: String) -> Bool {
        let latest = sanitize(version: version)
        let current = sanitize(version: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
        if shouldUpdate(currentVersion: current, latestVersion: latest) {
            if !automatic || persistenceManager.fetchLatestUpdate() != latest {
                NSLog("Update: latest available")
                persistenceManager.set(latestUpdate: latest)
                return true
            } else {
                NSLog("Update: latest suppressed")
                return false
            }
        } else {
            NSLog("Update: latest not found")
            return false
        }
    }
    
    /// Checks whether version should be updated.
    ///
    /// - Parameters:
    ///   - currentVersion: Current version to update from.
    ///   - latestVersion: Latest version to update to.
    /// - Returns: True if should be updated, false otherwise.
    private func shouldUpdate(currentVersion: String, latestVersion: String) -> Bool {
        if let current = split(version: currentVersion),
            let latest = split(version: latestVersion) {
            for i in 0 ..< max(current.count, latest.count) {
                let currentInt = i < current.count ? current[i] : 0
                let latestInt = i < latest.count ? latest[i] : 0
                if currentInt != latestInt {
                    return currentInt < latestInt
                }
            }
        }
        return false
    }
    
    /// Opens browser to download latest version.
    ///
    /// - Parameter url: Download URL for latest version.
    private func downloadUpdate(withUrl url: String) {
        NSWorkspace.shared().open(URL(string: url)!)
    }
    
    /// Split string version into integer parts.
    ///
    /// - Parameter version: String version.
    /// - Returns: Array of integer parts or nil.
    private func split(version: String) -> [Int]? {
        var intParts = [Int]()
        let parts = version.characters.split(separator: ".")
        for part in parts {
            if let intPart = Int(String(part)) {
                intParts.append(intPart)
            } else {
                return nil
            }
        }
        return intParts
    }
    
    /// Sanitizes version from prefixes.
    ///
    /// - Parameter version: String version with or without prefixes.
    /// - Returns: Sanitized version string.
    private func sanitize(version: String) -> String {
        var theVersion = version
        if version.characters.count > 0 && theVersion.hasPrefix("v") {
            theVersion.remove(at: version.startIndex)
        }
        return theVersion
    }
    
}
