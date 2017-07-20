//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, StateObserverDelegate {
    
    let statusItem: NSStatusItem
    let connectionMenuItem: NSMenuItem
    
    let stateObserver = StateObserver()
    
    override init() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        connectionMenuItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        connectionMenuItem.isEnabled = false
        
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that Notification Center defaults can be inaccessible
        if !stateObserver.checkNotificationCenterAvailable() {
            UiHelper.criticalErrorAlert(
                message: "This application requires the Notification Center, which cannot be found.",
                informative: "You must be running macOS before OS X 10.8, which is currently not supported.")
            NSApplication.shared().terminate(self)
        }
        
        LXDevice.sharedInstance()?.transitionSpeed = 30
        
        // Status button
        if let button = statusItem.button {
            button.image = UiHelper.createTemplateImage("StatusBarButtonImage-Unknown")
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
        reload()
        
        stateObserver.attach(delegate: self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        reload()
    }
    
    // MARK: StateObserverDelegate
    
    func stateObserver(valueChanged value: StateObserverValue) {
        let (color, imageName) = { () -> (NSColor, String) in
            switch value {
            case .doNotDisturbOff:
                return (Constants.lightColorAvailable, "StatusBarButtonImage-Available")
            case .doNotDisturbOn:
                return (Constants.lightColorBusy, "StatusBarButtonImage-Busy")
            case .screenLocked, .detached:
                return (Constants.lightColorLocked, "StatusBarButtonImage-Unknown")
            }
        }()
        
        if let device = LXDevice.sharedInstance(), device.connected == true {
            device.color = color.cgColor
        }
        
        if let button = statusItem.button {
            button.image = UiHelper.createTemplateImage(imageName)
        }
    }
    
    // MARK: Commands
    
    // Refreshes UI elements.
    func reload() {
        stateObserver.reload()
        
        connectionMenuItem.title = "Status: " + (LXDevice.sharedInstance()?.connected == true ? "Connected" : "Not connected")
    }
    
    // MARK: Selectors
    
    // Opens system preferences pane to keyboard shortcuts.
    func setKeyboardShortcutAction(sender: AnyObject) {
        UiHelper.preferencesKeyboardShortcuts()
    }
    
    // Terminates application.
    func quitAction(sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }

}
