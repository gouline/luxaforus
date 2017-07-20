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
    
    let stateObserver = StateObserver()
    let menuController = MenuController()
    
    override init() {
        super.init()
        
        menuController.delegate = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check that Notification Center defaults can be inaccessible
        if !stateObserver.checkNotificationCenterAvailable() {
            UiHelper.criticalErrorAlert(
                message: "This application requires the Notification Center, which cannot be found.",
                informative: "You must be running macOS before OS X 10.8, which is currently not supported.")
            NSApplication.shared().terminate(self)
        }
        
        LXDevice.sharedInstance()?.transitionSpeed = 30
        
        // Status button and menu
        //statusItem.button?.image = UiHelper.createTemplateImage("StatusBarButtonImage-Unknown")
        
        stateObserver.attach(delegate: self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stateObserver.detach()
    }
    
    // MARK: StateObserverDelegate
    
    func stateObserver(valueChanged value: StateObserverValue) {
        let (color, imageName) = { () -> (NSColor, String) in
            switch value {
            case .doNotDisturbOff:
                return (Constants.lightColorAvailable, "StatusBarButtonImage-Available")
            case .doNotDisturbOn:
                return (Constants.lightColorBusy, "StatusBarButtonImage-Busy")
            case .screenLocked, .detached:
                return (Constants.lightColorLocked, "StatusBarButtonImage-Unknown")
            }
        }()
        
        if let device = LXDevice.sharedInstance(), device.connected == true {
            device.color = color.cgColor
        }
        
        print(imageName)
        
        //statusItem.button?.image = UiHelper.createTemplateImage(imageName)
    }
    
    // MARK: MenuControllerDelegate
    
    func menuWillOpen() {
        stateObserver.reload()
        
        menuController.update(connectionState: LXDevice.sharedInstance()?.connected == true ? .connected : .disconnected)
    }

}
