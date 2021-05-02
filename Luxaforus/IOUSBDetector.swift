//
//  IOUSBDetector.swift
//  Luxaforus
//
//  Created by mgouline on 27/7/17.
//  Copyright © 2017 Mike Gouline. All rights reserved.
//

import Darwin
import IOKit
import IOKit.usb
import Foundation

// Adapted from https://stackoverflow.com/a/39662693/818393

class IOUSBDetector {
    
    private let vendorID: Int
    private let productID: Int
    
    var callbackQueue: DispatchQueue?
    var callback: ((_ detector: IOUSBDetector, _ event: Event, _ service: io_service_t) -> Void)?
    
    private let internalQueue: DispatchQueue
    
    private let notifyPort: IONotificationPortRef
    
    private var matchedIterator: io_iterator_t = 0
    private var terminatedIterator: io_iterator_t = 0
    
    init?(vendorID: Int, productID: Int) {
        self.vendorID = vendorID
        self.productID = productID
        self.internalQueue = DispatchQueue(label: "IODetector")
        
        let notifyPort = IONotificationPortCreate(kIOMasterPortDefault)
        guard notifyPort != nil else { return nil }
        
        self.notifyPort = notifyPort!
        IONotificationPortSetDispatchQueue(notifyPort, self.internalQueue)
    }
    
    deinit {
        stopDetection()
    }
    
    /// Starts detection loop.
    ///
    /// - Returns: True if successful, false if error.
    func startDetection() -> Bool {
        guard matchedIterator == 0 else { return true }
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        matchingDict[kUSBVendorID] = NSNumber(value: vendorID)
        matchingDict[kUSBProductID] = NSNumber(value: productID)
        
        let matchCallback: IOServiceMatchingCallback = { (userData, iterator) in
            let detector = Unmanaged<IOUSBDetector>.fromOpaque(userData!).takeUnretainedValue()
            detector.dispatchEvent(event: .matched, iterator: iterator)
        }
        let termCallback: IOServiceMatchingCallback = { (userData, iterator) in
            let detector = Unmanaged<IOUSBDetector>.fromOpaque(userData!).takeUnretainedValue()
            detector.dispatchEvent(event: .terminated, iterator: iterator)
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let addMatchError = IOServiceAddMatchingNotification(self.notifyPort,
                                                             kIOFirstMatchNotification,
                                                             matchingDict,
                                                             matchCallback,
                                                             selfPtr,
                                                             &self.matchedIterator)
        let addTermError = IOServiceAddMatchingNotification(self.notifyPort,
                                                            kIOTerminatedNotification,
                                                            matchingDict,
                                                            termCallback,
                                                            selfPtr,
                                                            &self.terminatedIterator)
        
        guard addMatchError == 0 && addTermError == 0 else {
            if self.matchedIterator != 0 {
                IOObjectRelease(self.matchedIterator)
                self.matchedIterator = 0
            }
            if self.terminatedIterator != 0 {
                IOObjectRelease(self.terminatedIterator)
                self.terminatedIterator = 0
            }
            return false
        }
        
        // This is required even if nothing was found to "arm" the callback
        dispatchEvent(event: .matched, iterator: self.matchedIterator)
        dispatchEvent(event: .terminated, iterator: self.terminatedIterator)
        
        return true
    }
    
    /// Stops detection queue.
    func stopDetection() {
        guard self.matchedIterator != 0 else { return }
        IOObjectRelease(self.matchedIterator)
        IOObjectRelease(self.terminatedIterator)
        self.matchedIterator = 0
        self.terminatedIterator = 0
    }
    
    private func dispatchEvent(event: Event, iterator: io_iterator_t) {
        repeat {
            let nextService = IOIteratorNext(iterator)
            guard nextService != 0 else { break }
            if let cb = self.callback, let q = self.callbackQueue {
                q.async {
                    cb(self, event, nextService)
                    IOObjectRelease(nextService)
                }
            } else {
                IOObjectRelease(nextService)
            }
        } while (true)
    }
    
    /// Detector events returned.
    ///
    /// - matched: Specified device detected.
    /// - terminated: Specified device terminated.
    enum Event {
        case matched
        case terminated
    }
    
}
