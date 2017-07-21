//
//  LXDevice.m
//  Luxafor-OSX
//
//  Created by Aigars Silavs on 12/04/15.
//  Copyright (c) 2015 draugiem. All rights reserved.
//

#import "LXDevice.h"
#include "hidapi.h"

#define kLuxaforVendorId   0x04d8
#define kLuxafotProcuctId  0xf372

#define kLuxaforOperationSize 9

@implementation LXDevice

+ (LXDevice *)sharedInstance
{
    static LXDevice *sharedLuxaforDevice = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLuxaforDevice = [self new];
    });
    return sharedLuxaforDevice;
}

- (void)setColor:(CGColorRef)color
{
    size_t componentCount = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    
    char red, green, blue;
    
    if (componentCount == 4) { // RGB
        CGFloat alpha = components[3];
        red = (char)(components[0] * alpha * 255);
        green = (char)(components[1] * alpha * 255);
        blue = (char)(components[2] * alpha * 255);
    } else if (componentCount == 2) { // Gray
        CGFloat alpha = components[1];
        red = green = blue = (char)(components[0] * alpha * 255);
    } else {
        return;
    }
    
    unsigned char luxaforOperation[kLuxaforOperationSize];
    
    luxaforOperation[0] = 0x0;   //report id
    luxaforOperation[1] = 2;     //continious transition
    luxaforOperation[2] = 0xFF;  //all leds
    luxaforOperation[3] = red;   //red color component
    luxaforOperation[4] = green; //green color component
    luxaforOperation[5] = blue;  //blue color component
    luxaforOperation[6] = _transitionSpeed;  //transition speed
    
    [self performLuxoforOperation:luxaforOperation];
}

- (void)performLuxoforOperation:(unsigned char *)luxoforOperation
{
    hid_device *hidHandle = hid_open(kLuxaforVendorId, kLuxafotProcuctId, NULL);
    
    if (hidHandle != NULL) {
        hid_write(hidHandle, luxoforOperation, kLuxaforOperationSize);
        hid_close(hidHandle);
    }
}

- (BOOL)connected
{
    hid_device *hidHandle = hid_open(kLuxaforVendorId, kLuxafotProcuctId, NULL);
    BOOL connected = hidHandle != NULL;
    
    if (connected) {
        hid_close(hidHandle);
    }
    
    return connected;
}

- (void)dealloc
{
    hid_exit();
}

@end
