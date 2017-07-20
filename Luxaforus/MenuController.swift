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
        
        connectionItem = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        connectionItem.isEnabled = false
        
        super.init()
        
        menu.addItem(connectionItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Set Do Not Disturb shortcut", action: #selector(setKeyboardShortcutAction(sender:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Luxaforus", action: #selector(quitAction(sender:)), keyEquivalent: "q"))
        menu.delegate = self
        
        statusItem.menu = menu
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        delegate?.menuWillOpen()
    }
    
    func update(connectionState state: MenuConnectionState) {
        connectionItem.title = "Status: \(state.rawValue)"
    }
    
    // Opens system preferences pane to keyboard shortcuts.
    func setKeyboardShortcutAction(sender: AnyObject) {
        UiHelper.preferencesKeyboardShortcuts()
    }
    
    // Terminates application.
    func quitAction(sender: AnyObject) {
        NSApplication.shared().terminate(self)
    }
    
}

protocol MenuControllerDelegate: class {
 
    func menuWillOpen()
    
}

enum MenuConnectionState: String {
    case connected = "Connected"
    case disconnected = "Not connected"
}
