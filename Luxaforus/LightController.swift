//
//  LightController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 21/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class LightController {
    
    private var brightness: CGFloat = 1.0
    
    private var currentColor: NSColor? = nil
    
    /// Updates current color of the light.
    ///
    /// - Parameter theColor: Color value (ignores alpha - set brightness for that).
    func update(color theColor: NSColor) {
        NSLog("Light: color=%@", theColor)
        
        currentColor = theColor
        
        getDevice(onlyConnected: true)?.color = theColor.withAlphaComponent(brightness)
    }
    
    /// Updates transition speed for colors.
    ///
    /// - Parameter theSpeed: Transition speed as a 8-bit integer.
    func update(transitionSpeed theSpeed: Int8) {
        NSLog("Light: transitionSpeed=%d", theSpeed)
        
        getDevice(onlyConnected: true)?.transitionSpeed = theSpeed
    }
    
    /// Updates brightness of the light.
    ///
    /// - Parameter theBrightness: Brightness value within same threshold as alpha.
    func update(brightness theBrightness: CGFloat) {
        brightness = theBrightness
        
        if let replayColor = currentColor {
            update(color: replayColor)
        }
    }
    
    /// Updates dimmed status. Shortcut for updating brightness (see LightBrightness constants).
    ///
    /// - Parameter isDimmed: True for dimmed, false for normal.
    func update(dimmed isDimmed: Bool) {
        update(brightness: isDimmed ? LightBrightness.dimmed : LightBrightness.normal)
    }
    
    /// Retrieves active device from LXDevice.
    ///
    /// - Parameter enabled: True to only return device if connected, false otherwise.
    /// - Returns: Device instance or null.
    private func getDevice(onlyConnected enabled: Bool) -> LXDevice? {
        let device = LXDevice.sharedInstance()
        if device?.connected ?? false || !enabled {
            return device
        }
        return nil
    }
    
}

/// Color states for the light.
class LightColor {
    static let available = NSColor.green
    static let busy = NSColor.red
    static let locked = NSColor.black
}

/// Brightness states for the light.
class LightBrightness {
    static let normal: CGFloat = 1.0
    static let dimmed: CGFloat = 0.1
}
