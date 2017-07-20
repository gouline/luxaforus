//
//  StateObserver.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class StateObserver: NSObject {
    
    private let notificationCenterDefaults: UserDefaults?
    
    private weak var delegate: StateObserverDelegate? = nil
    
    private(set) var isDoNotDisturb = false
    private(set) var isScreenLocked = false
    
    // Checks if notification center is available.
    var isNotificationCenterAvailable: Bool {
        get {
            return notificationCenterDefaults != nil
        }
    }

    override init() {
        notificationCenterDefaults = UserDefaults(suiteName: "com.apple.notificationcenterui")
    }
    
    // MARK: Lifecycle
    
    // Attaches state observers when application starts up.
    func attach(delegate theDelegate: StateObserverDelegate) {
        delegate = theDelegate
        
        // Add screen lock/unlock observers
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(screenIsLockedAction(sender:)),
                                                            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),
                                                            object: nil)
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(screenIsUnlockedAction(sender:)),
                                                            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),
                                                            object: nil)
        
        // Add Do Not Disturb mode observer
        notificationCenterDefaults?.addObserver(self, forKeyPath: "doNotDisturb", options: .new, context: nil)
        
        // Check initial value for Do Not Disturb mode
        reload()
    }
    
    // Detaches state observers when application closes.
    func detach() {
        // Remove Do Not Disturb mode observer
        notificationCenterDefaults?.removeObserver(self, forKeyPath: "doNotDisturb")
        
        // Remove screen lock/unlock observers
        DistributedNotificationCenter.default().removeObserver(self)
        
        delegate?.stateObserver(valueChanged: .detached)
        delegate = nil
    }
    
    // MARK: Checks
    
    // Checks if notification
    func checkNotificationCenterAvailable() -> Bool {
        return notificationCenterDefaults != nil
    }
    
    // Refreshes states that can be read without notifications.
    func reload() {
        update(isDoNotDisturb: notificationCenterDefaults?.bool(forKey: "doNotDisturb") ?? false)
    }
    
    // MARK: Observers
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "doNotDisturb" {
            if let newValue = change?[.newKey] as? Bool { //__NSCFBoolean
                update(isDoNotDisturb: newValue)
            }
        }
    }
    
    @objc private func screenIsLockedAction(sender: AnyObject) {
        update(isScreenLocked: true)
    }
    
    @objc private func screenIsUnlockedAction(sender: AnyObject) {
        update(isScreenLocked: false)
    }
    
    // MARK: Updaters
    
    private func update(isDoNotDisturb newValue: Bool) {
        isDoNotDisturb = newValue
        notifyDelegate()
    }
    
    private func update(isScreenLocked newValue: Bool) {
        isScreenLocked = newValue
        notifyDelegate()
    }
    
    private func notifyDelegate() {
        delegate?.stateObserver(valueChanged: { () -> (StateObserverValue) in
            if isScreenLocked {
                return .screenLocked
            } else if isDoNotDisturb {
                return .doNotDisturbOn
            } else {
                return .doNotDisturbOff
            }
        }())
    }
    
}

protocol StateObserverDelegate: class {

    // State changed to a new one.
    func stateObserver(valueChanged value: StateObserverValue)
    
}

enum StateObserverValue {
    
    // Do Not Disturb enabled (screen unlocked).
    case doNotDisturbOn
    
    // Do Not Diturb disabled (screen unlocked).
    case doNotDisturbOff
    
    // Screen locked (or sleep mode).
    case screenLocked
    
    // Observer got detached.
    case detached
    
}
