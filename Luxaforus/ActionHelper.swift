//
//  ActionHelper.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Mike Gouline. All rights reserved.
//

import Foundation

class ActionHelper {
    
    /// Opens system preferences pane to keyboard shortcuts.
    static func preferencesKeyboardShortcuts() {
        let scriptValue = "tell application \"System Preferences\"\n"
            + "   activate\n"
            + "   reveal anchor \"shortcutsTab\" of pane id \"com.apple.preference.keyboard\"\n"
            + "end tell\n"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptValue) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
}
