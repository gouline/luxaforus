//
//  UiHelper.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Foundation

class UiHelper {
    
    // Shows message with an OK button.
    static func criticalErrorAlert(message: String, informative: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Creates image by name and sets its 'template' flag on.
    static func createTemplateImage(_ name: String) -> NSImage? {
        let image = NSImage(named: name)
        image?.isTemplate = true
        return image
    }
    
    // Opens system preferences pane to keyboard shortcuts.
    static func preferencesKeyboardShortcuts() {
        let scriptValue = "tell application \"System Preferences\"\n" +
            "   activate\n" +
            "   reveal anchor \"shortcutsTab\" of pane id \"com.apple.preference.keyboard\"\n" +
        "end tell\n"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptValue) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
}
