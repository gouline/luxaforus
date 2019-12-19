//
//  NotificationManager.swift
//  Luxaforus
//
//  Created by Mike Gouline on 27/7/17.
//  Copyright © 2017 Traversal.space. All rights reserved.
//

import Cocoa

class NotificationManager : NSObject, NSUserNotificationCenterDelegate {
 
    private var callbacks = [String: ((NSUserNotification) -> Bool)]()
    
    /// Attaches notification center delegate.
    func attach() {
        NSUserNotificationCenter.default.delegate = self
    }
    
    /// Detaches notification center delegate and clears notifications.
    func detach() {
        callbacks.removeAll()
        
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
        NSUserNotificationCenter.default.delegate = nil
    }
    
    /// Delivers notification with a callback for activation.
    ///
    /// - Parameters:
    ///   - notification: Notification to deliver.
    ///   - activateCallback: Callback for when notification is activated, returns whether or not to remove it.
    func deliver(_ notification: NSUserNotification, activateCallback: @escaping ((NSUserNotification) -> Bool)) {
        callbacks[notification.identifier!] = activateCallback
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // MARK: - NSUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        var isRemove = true
        if let identifier = notification.identifier {
            if let callback = callbacks.removeValue(forKey: identifier) {
                isRemove = callback(notification)
            }
        }
        if isRemove {
            center.removeDeliveredNotification(notification)
        }
    }
    
}
