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
    
    weak var delegate: MenuControllerDelegate? = nil

    override init() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        
        connectionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu.addItem(connectionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        
        let preferencesMenu = NSMenu()
        
        dimStateItem = NSMenuItem(title: "Dim light", action: #selector(changeDimStateAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(dimStateItem)
        
        preferencesMenu.addItem(NSMenuItem.separator())
        
        let setKeyboardShortcutItem = NSMenuItem(title: "Set keyboard shortcut", action: #selector(setKeyboardShortcutAction(sender:)), keyEquivalent: "")
        preferencesMenu.addItem(setKeyboardShortcutItem)
        
        preferencesItem.submenu = preferencesMenu
        
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Luxaforus", action: #selector(quitAction(sender:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        super.init()
        
        MenuController.assignTarget(toMenu: menu, target: self)
        menu.delegate = self
        
        statusItem.menu = menu
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
    
    /// Updates connection state text.
    func update(connectionState state: MenuConnectionState) {
        connectionItem.title = "Status: \(state.rawValue)"
    }
    
    /// Updates status item image state.
    func update(imageState state: MenuImageState) {
        let image = NSImage(named: state.rawValue)
        image?.isTemplate = true
        statusItem.button?.image = image
    }
    
    /// Updates on/off state of the dim item.
    ///
    /// - Parameter isDimmed: True if dimmed, false otherwise.
    func update(dimState isDimmed: Bool) {
        dimStateItem.state = isDimmed ? NSOnState : NSOffState
    }
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        delegate?.menuWillOpen()
    }
    
    // MARK: - Selectors
    
    /// Responds to 'Dim light' action.
    func changeDimStateAction(sender: AnyObject) {
        let newEnabled = !(dimStateItem.state == NSOnState)
        if delegate?.menu(action: .dimState(enabled: newEnabled)) ?? false {
            update(dimState: newEnabled)
        }
    }
    
    /// Responds to 'Set keyboard shortcut' action.
    func setKeyboardShortcutAction(sender: AnyObject) {
        _ = delegate?.menu(action: .setKeyboardShortcut)
    }
    
    /// Responds to 'Quit Luxaforus' action.
    func quitAction(sender: AnyObject) {
        _ = delegate?.menu(action: .quit)
    }
    
}

protocol MenuControllerDelegate: class {
 
    /// Menu is about to open from status button click.
    func menuWillOpen()
    
    
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
/// - setKeyboardShortcut: Action to set keyboard shortcut for Do Not Disturb.
/// - dimState: Enable/disable light dimming.
/// - quit: Action to quit the application.
enum MenuAction {
    case setKeyboardShortcut
    case dimState(enabled: Bool)
    case quit
}
