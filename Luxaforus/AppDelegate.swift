//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, StateObserverDelegate, MenuControllerDelegate {
    
    let stateObserver = StateObserver()
    let menuController = MenuController()
    
    override init() {
        super.init()
        
        menuController.delegate = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that Notification Center defaults can be inaccessible
        if !stateObserver.checkNotificationCenterAvailable() {
            ActionHelper.criticalErrorAlert(
                message: "This application requires the Notification Center, which cannot be found.",
                informative: "You must be running macOS before OS X 10.8, which is currently not supported.")
            NSApplication.shared().terminate(self)
        }
        
        LXDevice.sharedInstance()?.transitionSpeed = 30
        
        menuController.update(imageState: MenuImageState.unknown)
        
        stateObserver.attach(delegate: self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
    }
    
    // MARK: - StateObserverDelegate
    
    func stateObserver(valueChanged value: StateObserverValue) {
        let (color, imageState) = { () -> (NSColor, MenuImageState) in
            switch value {
            case .doNotDisturbOff:
                return (LightColor.available, .available)
            case .doNotDisturbOn:
                return (LightColor.busy, .busy)
            case .screenLocked, .detached:
                return (LightColor.locked, .unknown)
            }
        }()
        
        if let device = LXDevice.sharedInstance(), device.connected == true {
            device.color = color.cgColor
        }
        
        menuController.update(imageState: imageState)
    }
    
    // MARK: - MenuControllerDelegate
    
    func menuWillOpen() {
        stateObserver.reload()
        
        menuController.update(connectionState: LXDevice.sharedInstance()?.connected == true ? .connected : .disconnected)
    }
    
    func menu(action theAction: MenuAction) {
        switch theAction {
        case .setKeyboardShortcut:
            ActionHelper.preferencesKeyboardShortcuts()
        case .quit:
            NSApplication.shared().terminate(self)
        }
    }

}


/// Color states for the light.
class LightColor {
    static let available = NSColor.green
    static let busy = NSColor.red
    static let locked = NSColor.black
}
