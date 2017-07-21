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
    
    private let stateObserver = StateObserver()
    private let menuController = MenuController()
    private let lightController = LightController()
    private let preferenceManager = PreferenceManager()
    
    override init() {
        super.init()
        
        menuController.delegate = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that Notification Center defaults can be inaccessible
        if !stateObserver.checkNotificationCenterAvailable() {
            let alert = NSAlert()
            alert.messageText = "This application requires the Notification Center, which cannot be found."
            alert.informativeText = "You must be running macOS before OS X 10.8, which is currently not supported."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            if alert.runModal() == NSAlertFirstButtonReturn {
                NSApplication.shared().terminate(self)
            }
        }
        
        lightController.update(transitionSpeed: 30)
        update(lightDimmed: preferenceManager.fetchDimmed(), updatePreference: false, updateMenu: true)
        
        menuController.update(imageState: MenuImageState.unknown)
        
        stateObserver.attach(delegate: self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
    }
    
    // MARK: - Actions
    
    private func update(lightDimmed isDimmed: Bool, updatePreference: Bool, updateMenu: Bool) {
        if updatePreference {
            preferenceManager.set(dimmed: isDimmed)
        }
        if updateMenu {
            menuController.update(dimState: isDimmed)
        }
        lightController.update(dimmed: isDimmed)
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
        
        lightController.update(color: color)

        menuController.update(imageState: imageState)
    }
    
    // MARK: - MenuControllerDelegate
    
    func menu(action theAction: MenuAction) -> Bool {
        switch theAction {
        case .dimState(let enabled):
            update(lightDimmed: enabled, updatePreference: true, updateMenu: false)
        case .setKeyboardShortcut:
            let alert = NSAlert()
            alert.messageText = "Open keyboard shortcuts?"
            alert.informativeText = "Select 'Mission Control' from the sidebar, enable 'Turn Do Not Disturb On/Off' and double-click the keyboard shortcut to set a new one."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Proceed")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == NSAlertFirstButtonReturn {
                ActionHelper.preferencesKeyboardShortcuts()
            }
        case .quit:
            NSApplication.shared().terminate(self)
        }
        return true
    }
    
    func menuWillOpen() {
        stateObserver.reload()
        
        menuController.update(connectionState: LXDevice.sharedInstance()?.connected == true ? .connected : .disconnected)
    }

}
