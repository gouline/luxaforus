//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    
    
    let statusItem: NSStatusItem
    let connectionMenuItem: NSMenuItem
    
    let notificationCenterDefaults: UserDefaults?
    
    var isScreenLocked = false
    
    override init() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        connectionMenuItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        connectionMenuItem.isEnabled = false
        
        notificationCenterDefaults = UserDefaults(suiteName: "com.apple.notificationcenterui")
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if notificationCenterDefaults == nil {
            criticalError(message: "This application requires the Notification Center, which cannot be found.",
                          informative: "You must be running macOS before OS X 10.8, which is currently not supported.")
            NSApplication.shared().terminate(self)
        }
        
        // Status button
        if let button = statusItem.button {
            button.image = createTemplateImage("StatusBarButtonImage-Unknown")
        }
        
        // Status menu
        let menu = NSMenu()
        menu.addItem(connectionMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Set Do Not Disturb shortcut", action: #selector(setKeyboardShortcutAction(sender:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Luxaforus", action: #selector(quitAction(sender:)), keyEquivalent: "q"))
        menu.delegate = self
        statusItem.menu = menu
        
        // Check initial state
        setLightDisabled(false)
        checkConnectionStatus()
        checkDoNotDisturb()
        
        // Add notification listeners
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(screenIsLockedAction(sender:)),
                                                            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),
                                                            object: nil)
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(screenIsUnlockedAction(sender:)),
                                                            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),
                                                            object: nil)
        notificationCenterDefaults?.addObserver(self, forKeyPath: "doNotDisturb", options: .new, context: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        setLightDisabled(true)
        
        // Remove notification listeners
        notificationCenterDefaults?.removeObserver(self, forKeyPath: "doNotDisturb")
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "doNotDisturb" {
            if let newValue = change?[.newKey] as? Bool { //__NSCFBoolean
                setDoNotDisturb(newValue)
            }
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        checkConnectionStatus()
        checkDoNotDisturb()
    }
    
    // MARK: Commands
    
    // Checks Luxafor connection status and updates menu item.
    func checkConnectionStatus() {
        let isConnected = LXDevice.sharedInstance().connected
        connectionMenuItem.title = "Status: " + (isConnected ? "Connected" : "Not connected")
    }
    
    // Reads current value and sets light value.
    func checkDoNotDisturb() {
        let doNotDisturbValue = notificationCenterDefaults?.bool(forKey: "doNotDisturb")
        setDoNotDisturb(doNotDisturbValue!)
    }
    
    // Sets light value according to DND being enabled/disabled.
    func setDoNotDisturb(_ value: Bool) {
        if let button = statusItem.button {
            button.image = createTemplateImage(value ? "StatusBarButtonImage-Busy" : "StatusBarButtonImage-Available")
        }
        
        if !isScreenLocked {
            setLightColor(value ? Constants.lightColorBusy : Constants.lightColorAvailable)
        }
        
        print("DND: \(value)")
    }
    
    // Sets light color (if device available).
    func setLightColor(_ color: NSColor) {
        if let device = LXDevice.sharedInstance(), device.connected == true {
            device.color = color.cgColor
        }
    }
    
    // Disables light, which turns it off until re-enabled (if device available).
    func setLightDisabled(_ disabled: Bool) {
        if let device = LXDevice.sharedInstance(), device.connected == true {
            device.lightDisabled = disabled
        }
    }
    
    // MARK: Selectors
    
    // Opens system preferences pane to keyboard shortcuts.
    func setKeyboardShortcutAction(sender: AnyObject) {
        let scriptValue = "tell application \"System Preferences\"\n" +
                            "   activate\n" +
                            "   reveal anchor \"shortcutsTab\" of pane id \"com.apple.preference.keyboard\"\n" +
                            "end tell\n"
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: scriptValue) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    // Sets light mode for screen off.
    func screenIsLockedAction(sender: AnyObject) {
        isScreenLocked = true
        
        setLightDisabled(true)
        
        print("Screen locked")
    }
    
    // Resets light mode for screen on.
    func screenIsUnlockedAction(sender: AnyObject) {
        isScreenLocked = false
        
        setLightDisabled(false)
        checkDoNotDisturb()
        
        print("Screen unlocked")
    }
    
    // Terminates application.
    func quitAction(sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    // MARK: Utils
    
    // Shows message with an OK button.
    func criticalError(message: String, informative: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // Creates image by name and sets its 'template' flag on.
    func createTemplateImage(_ name: String) -> NSImage? {
        let image = NSImage(named: name)
        image?.isTemplate = true
        return image
    }

}
