//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, StateObserverDelegate, MenuControllerDelegate, LightControllerDelegate, SlackControllerDelegate {
    
    private let stateObserver = StateObserver()
    private let persistenceManager = PersistenceManager()
    private var notificationManager = NotificationManager()
    
    private let menuController: MenuController
    private let lightController: LightController
    private let slackController: SlackController
    private let updateController: UpdateController
    
    override init() {
        menuController = MenuController()
        lightController = LightController()
        slackController = SlackController(persistenceManager: persistenceManager)
        updateController = UpdateController(notificationManager: notificationManager, persistenceManager: persistenceManager)
        
        super.init()
        
        lightController(connectedChanged: LXDevice.sharedInstance()?.connected == true)
        
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
        
        menuController.update(imageState: MenuImageState.unknown)
        
        lightController.attach(delegate: self)
        lightController.update(transitionSpeed: 30)
        update(lightDimmed: persistenceManager.fetchDimmed(), updatePersistence: false, updateMenu: true)
        update(ignoreUpdates: persistenceManager.fetchIgnoreUpdates(), updatePersistence: false, updateMenu: true)
        
        notificationManager.attach()
        slackController.attach(delegate: self)
        stateObserver.attach(delegate: self)
        
        // Delay update check to avoid overwhelming user with information
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
            self.updateController.check(automatic: true)
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
        slackController.detach()
        lightController.detach()
        notificationManager.detach()
    }
    
    // MARK: - Actions
    
    private func update(lightDimmed isDimmed: Bool, updatePersistence: Bool, updateMenu: Bool) {
        if updatePersistence {
            persistenceManager.set(dimmed: isDimmed)
        }
        if updateMenu {
            menuController.update(dimState: isDimmed)
        }
        lightController.update(dimmed: isDimmed)
    }
    
    private func update(ignoreUpdates isIgnored: Bool, updatePersistence: Bool, updateMenu: Bool) {
        if updatePersistence {
            persistenceManager.set(ignoreUpdates: isIgnored)
        }
        if updateMenu {
            menuController.update(ignoreUpdates: isIgnored)
        }
    }
    
    private func update(slackLoggedIn isLoggedIn: Bool, updateMenu: Bool) {
        if updateMenu {
            menuController.update(slackLoggedIn: isLoggedIn)
        }
    }
    
    // MARK: - Delegates
    
    // StateObserverDelegate
    func stateObserver(valueChanged value: StateObserverValue) {
        let (color, imageState, snoozed) = { () -> (NSColor, MenuImageState, Bool?) in
            switch value {
            case .doNotDisturbOff:
                return (LightColor.available, .available, false)
            case .doNotDisturbOn:
                return (LightColor.busy, .busy, true)
            case .screenLocked, .detached:
                return (LightColor.locked, .unknown, nil)
            }
        }()
        
        lightController.update(color: color)

        menuController.update(imageState: imageState)
        
        if snoozed != nil {
            slackController.update(snoozed: snoozed!)
        }
    }
    
    // MenuControllerDelegate
    func menu(action theAction: MenuAction) -> Bool {
        switch theAction {
        case .opening:
            break
        case .dimState(let enabled):
            update(lightDimmed: enabled, updatePersistence: true, updateMenu: false)
        case .ignoreUpdatesState(let enabled):
            update(ignoreUpdates: enabled, updatePersistence: true, updateMenu: false)
        case .slackIntegration:
            if slackController.isLoggedIn {
                slackController.removeIntegration()
            } else {
                slackController.addIntegration()
            }
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
        case .checkForUpdates:
            updateController.check(automatic: false)
        case .quit:
            NSApplication.shared().terminate(self)
        }
        return true
    }
    
    // LightControllerDelegate
    func lightController(connectedChanged connected: Bool) {
        menuController.update(connectionState: connected ? .connected : .disconnected)
    }
    
    // SlackControllerDelegate
    func slackController(stateChanged loggedIn: Bool) {
        menuController.update(slackLoggedIn: loggedIn)
    }

}
