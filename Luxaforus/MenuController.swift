//
//  MenuController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class MenuController: NSObject, NSMenuDelegate {
    
    let statusItem: NSStatusItem
    
    let menu = NSMenu()
    
    private let connectionItem: NSMenuItem
    
    weak var delegate: MenuControllerDelegate? = nil

    override init() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        
        connectionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        menu.addItem(connectionItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let doNotDisturbShortcutItem = NSMenuItem(title: "Set Do Not Disturb shortcut", action: #selector(setKeyboardShortcutAction(sender:)), keyEquivalent: "")
        menu.addItem(doNotDisturbShortcutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Luxaforus", action: #selector(quitAction(sender:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        super.init()
        
        for item in menu.items where item.action != nil {
            item.target = self
        }
        menu.delegate = self
        
        statusItem.menu = menu
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
    
    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        delegate?.menuWillOpen()
    }
    
    // MARK: - Selectors
    
    /// Opens system preferences pane to keyboard shortcuts.
    func setKeyboardShortcutAction(sender: AnyObject) {
        delegate?.menu(action: .setKeyboardShortcut)
    }
    
    /// Terminates application.
    func quitAction(sender: AnyObject) {
        delegate?.menu(action: .quit)
    }
    
}

protocol MenuControllerDelegate: class {
 
    /// Menu is about to open from status button click.
    func menuWillOpen()
    
    
    /// Menu action received.
    ///
    /// - Parameter theAction: Menu action type.
    func menu(action theAction: MenuAction)
    
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

enum MenuAction {
    case setKeyboardShortcut
    case quit
}
