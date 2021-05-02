//
//  StateObserver.swift
//  Luxaforus
//
//  Created by Mike Gouline on 20/7/17.
//  Copyright © 2017 Mike Gouline. All rights reserved.
//

import Cocoa

class StateObserver: NSObject {

    private let notificationCenterDefaults = UserDefaults(suiteName: "com.apple.notificationcenterui")

    // Key path for Do not disturb setting under the com.apple.notificationcenterui user defaults suite
    private let kDndKeyPath = "doNotDisturb"

    private weak var delegate: StateObserverDelegate? = nil
    
    private(set) var isDoNotDisturb = false
    private(set) var isScreenLocked = false
    
    /// Checks if notification center is available.
    var isNotificationCenterAvailable: Bool {
        get {
            return notificationCenterDefaults != nil
        }
    }

    deinit {
        // Ensure observations are not leaked if object is deallocated
        detach()
    }
    
    /// Attaches state observers when application starts up.
    func attach(delegate theDelegate: StateObserverDelegate) {
        // Check that a delegate was attached
        if delegate != nil { return }
        
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
        notificationCenterDefaults?.addObserver(self, forKeyPath: kDndKeyPath, options: .new, context: nil)
        
        // Check initial value for Do Not Disturb mode
        reload()
    }
    
    /// Detaches state observers when application closes.
    func detach() {
        // Check that a delegate was attached
        if delegate == nil { return }
        
        // Remove Do Not Disturb mode observer
        notificationCenterDefaults?.removeObserver(self, forKeyPath: kDndKeyPath)
        
        // Remove screen lock/unlock observers
        DistributedNotificationCenter.default().removeObserver(self)
        
        delegate?.stateObserver(valueChanged: .detached)
        delegate = nil
    }
    
    // MARK: - Checks
    
    /// Checks if notification
    func checkNotificationCenterAvailable() -> Bool {
        return notificationCenterDefaults != nil
    }
    
    /// Refreshes states that can be read without notifications.
    func reload() {
        update(isDoNotDisturb: notificationCenterDefaults?.bool(forKey: kDndKeyPath) ?? false)
    }
    
    // MARK: - Observers
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kDndKeyPath {
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
    
    // MARK: - Updaters
    
    private func update(isDoNotDisturb newValue: Bool) {
        NSLog("State: doNotDisturb=%@", newValue ? "true" : "false")
        
        isDoNotDisturb = newValue
        notifyDelegate()
    }
    
    private func update(isScreenLocked newValue: Bool) {
        NSLog("State: screenLocked=%@", newValue ? "true" : "false")
        
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

    /// State changed to a new one.
    func stateObserver(valueChanged value: StateObserverValue)
    
}

/// State representation value.
///
/// - doNotDisturbOn: Do Not Disturb enabled (screen unlocked).
/// - doNotDisturbOff: Do Not Disturb disabled (screen unlocked).
/// - screenLocked: Screen locked (or sleep mode).
/// - detached: Observer got detached.
enum StateObserverValue {
    case doNotDisturbOn
    case doNotDisturbOff
    case screenLocked
    case detached
}
