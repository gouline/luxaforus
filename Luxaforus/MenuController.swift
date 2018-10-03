//
//  MenuController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class MenuController: NSObject, NSMenuDelegate {
    
    private let statusItem: NSStatusItem
    
    private let menu = NSMenu()
    
    private let connectionItem: NSMenuItem
    private let dimStateItem: NSMenuItem
    private let ignoreUpdatesItem: NSMenuItem
    private let slackIntegrationItem: NSMenuItem
    
    weak var delegate: MenuControllerDelegate? = nil

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        connectionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu.addItem(connectionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        
        let preferencesMenu = NSMenu()
        
        dimStateItem = NSMenuItem(title: "Dim Light", action: #selector(changeDimStateAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(dimStateItem)
        
        ignoreUpdatesItem = NSMenuItem(title: "Ignore Updates", action: #selector(changeIgnoreUpdatesAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(ignoreUpdatesItem)
        
        preferencesMenu.addItem(NSMenuItem.separator())
        
        slackIntegrationItem = NSMenuItem(title: "", action: #selector(slackIntegrationAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(slackIntegrationItem)
        
        preferencesMenu.addItem(NSMenuItem.separator())
        
        let setKeyboardShortcutItem = NSMenuItem(title: "Set Keyboard Shortcut…", action: #selector(setKeyboardShortcutAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(setKeyboardShortcutItem)
        
        preferencesItem.submenu = preferencesMenu
        
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem(title: "Check for Updates", action: #selector(checkForUpdatesAction(sender:)), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Luxaforus", action: #selector(quitAction(sender:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        super.init()
        
        MenuController.assignTarget(toMenu: menu, target: self)
        menu.delegate = self
        
        statusItem.menu = menu
        
        // Defaults
        update(connectionState: .unknown)
        update(slackLoggedIn: false)
    }
    
    /// Assigns target to items and sub-items with actions.
    ///
    /// - Parameters:
    ///   - theMenu: Menu to traverse.
    ///   - target: Target to assign to items with action.
    private static func assignTarget(toMenu theMenu: NSMenu, target: AnyObject?) {
        for item in theMenu.items {
            if item.hasSubmenu {
                assignTarget(toMenu: item.submenu!, target: target)
            } else if item.action != nil {
                item.target = target
            }
        }
    }
    
    // MARK: - Actions
    
    /// Updates status item image state.
    ///
    /// - Parameter state: Menu image state enum.
    func update(imageState state: MenuImageState) {
        let image = NSImage(named: state.rawValue)
        image?.isTemplate = true
        statusItem.button?.image = image
    }
    
    /// Updates connection state text.
    ///
    /// - Parameter state: Connection state enum.
    func update(connectionState state: MenuConnectionState) {
        connectionItem.title = "Status: \(state.rawValue)"
    }
    
    /// Updates Slack integration text.
    ///
    /// - Parameter loggedIn: True if Slack logged in, false otherwise.
    func update(slackLoggedIn loggedIn: Bool) {
        slackIntegrationItem.title = loggedIn ? "Remove Slack Integration" : "Add Slack Integration"
    }
    
    /// Updates on/off state of the dim item.
    ///
    /// - Parameter isDimmed: True if dimmed, false otherwise.
    func update(dimState isDimmed: Bool) {
        dimStateItem.state = isDimmed ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    /// Updates ignore updates on/off state.
    ///
    /// - Parameter isIgnored: True if ignore, false otherwise.
    func update(ignoreUpdates isIgnored: Bool) {
        ignoreUpdatesItem.state = isIgnored ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        _ = delegate?.menu(action: .opening)
    }
    
    // MARK: - Selectors
    
    /// Responds to 'Dim light' action.
    @objc func changeDimStateAction(sender: AnyObject) {
        let newEnabled = !(dimStateItem.state == NSControl.StateValue.on)
        if delegate?.menu(action: .dimState(enabled: newEnabled)) ?? false {
            update(dimState: newEnabled)
        }
    }
    
    /// Responds to 'Ignore Updates' action.
    @objc func changeIgnoreUpdatesAction(sender: AnyObject) {
        let newEnabled = !(ignoreUpdatesItem.state == NSControl.StateValue.on)
        if delegate?.menu(action: .ignoreUpdatesState(enabled: newEnabled)) ?? false {
            update(ignoreUpdates: newEnabled)
        }
    }
    
    /// Add/remove Slack integration action.
    @objc func slackIntegrationAction(sender: AnyObject) {
        _ = delegate?.menu(action: .slackIntegration)
    }
    
    /// Responds to 'Set keyboard shortcut' action.
    @objc func setKeyboardShortcutAction(sender: AnyObject) {
        _ = delegate?.menu(action: .setKeyboardShortcut)
    }
    
    /// Responds to 'Check for Updates' action.
    @objc func checkForUpdatesAction(sender: AnyObject) {
        _ = delegate?.menu(action: .checkForUpdates)
    }
    
    /// Responds to 'Quit Luxaforus' action.
    @objc func quitAction(sender: AnyObject) {
        _ = delegate?.menu(action: .quit)
    }
    
}

protocol MenuControllerDelegate: class {
    
    /// Menu action received.
    ///
    /// - Parameter theAction: Menu action type.
    /// - Returns: True if action succeeded, false otherwise.
    func menu(action theAction: MenuAction) -> Bool
    
}

/// Connection state linked to the display text.
///
/// - connected: Device is connected and taking operations.
/// - disconnected: Device disconnected and unavailable.
/// - unknown: Connection status could not be determined.
enum MenuConnectionState: String {
    case connected = "Connected"
    case disconnected = "Not connected"
    case unknown = "Unknown"
}


/// Status button image state linked to the asset image name.
///
/// - available: Do Not Disturb is disabled.
/// - busy: Do Not Disturb is enabled.
/// - unknown: Unknown state, potentially error.
enum MenuImageState: String {
    case available = "StatusBarButtonImage-Available"
    case busy = "StatusBarButtonImage-Busy"
    case unknown = "StatusBarButtonImage-Unknown"
}


/// Menu actions with parameters.
///
/// - opening: Menu about to open.
/// - dimState: Enable/disable light dimming.
/// - disableUpdatesState: Enable/disable ignoring updates.
/// - slackIntegration: Add/remove Slack integration.
/// - setKeyboardShortcut: Action to set keyboard shortcut for Do Not Disturb.
/// - quit: Action to quit the application.
enum MenuAction {
    case opening
    case dimState(enabled: Bool)
    case ignoreUpdatesState(enabled: Bool)
    case slackIntegration
    case setKeyboardShortcut
    case checkForUpdates
    case quit
}
