//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem: NSStatusItem
    
    let notificationCenterDefaults: UserDefaults?
    
    override init() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        
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
            button.action = #selector(statusItemButtonAction(sender:))
        }
        
        // Status menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Luxaforus", action: #selector(quit(sender:)), keyEquivalent: ""))
        statusItem.menu = menu
        
        // Read initial value
        let doNotDisturbValue = notificationCenterDefaults?.bool(forKey: "doNotDisturb")
        setDoNotDisturb(doNotDisturbValue!)
        
        notificationCenterDefaults?.addObserver(self, forKeyPath: "doNotDisturb", options: .new, context: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        notificationCenterDefaults?.removeObserver(self, forKeyPath: "doNotDisturb")
    }
    
    // MARK: Commands
    
    func setDoNotDisturb(_ value: Bool) {
        if let button = statusItem.button {
            let statusImage = NSImage(named: value ? "StatusBarButtonImage-Busy" : "StatusBarButtonImage-Available")
            statusImage?.isTemplate = true
            button.image = statusImage
        }
        
        let device = LXDevice.sharedInstance()
        if device?.connected == true {
            device?.color = (value ? NSColor.red : NSColor.green).cgColor
        }
        
        print("Changed \(value)")
    }
    
    // MARK: Listeners
    
    func statusItemButtonAction(sender: AnyObject) {
        print("Some action")
    }
    
    func quit(sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "doNotDisturb" {
            if let newValue = change?[.newKey] as? Bool { //__NSCFBoolean
                setDoNotDisturb(newValue)
            }
        }
    }
    
    // MARK: Utils
    
    func criticalError(message: String, informative: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informative
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}

