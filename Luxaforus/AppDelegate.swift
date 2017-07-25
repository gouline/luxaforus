//
//  AppDelegate.swift
//  Luxaforus
//
//  Created by Mike Gouline on 30/6/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, StateObserverDelegate, MenuControllerDelegate, SlackControllerDelegate {
    
    private let stateObserver = StateObserver()
    private let persistenceManager = PersistenceManager()
    
    private let menuController: MenuController
    private let lightController: LightController
    private let slackController: SlackController
    
    override init() {
        menuController = MenuController()
        lightController = LightController()
        slackController = SlackController(persistenceManager: persistenceManager)
        
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
        update(lightDimmed: persistenceManager.fetchDimmed(), updatePersistence: false, updateMenu: true)
        
        menuController.update(imageState: MenuImageState.unknown)
        
        slackController.attach(delegate: self)
        stateObserver.attach(delegate: self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
        slackController.detach()
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
            menuController.update(connectionState: LXDevice.sharedInstance()?.connected == true ? .connected : .disconnected)
        case .dimState(let enabled):
            update(lightDimmed: enabled, updatePersistence: true, updateMenu: false)
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
        case .quit:
            NSApplication.shared().terminate(self)
        }
        return true
    }
    
    // SlackControllerDelegate
    func slackController(stateChanged loggedIn: Bool) {
        menuController.update(slackLoggedIn: loggedIn)
    }

}
