//
//  LXDevice.m
//  Luxafor-OSX
//
//  Created by Aigars Silavs on 12/04/15.
//  Copyright (c) 2015 draugiem. All rights reserved.
//

#import "LXDevice.h"
#include "hidapi.h"

#define kLuxaforOperationSize 9

const ushort kLuxaforVendorId = 0x04d8;
const ushort kLuxaforProductId = 0xf372;

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

- (void)setColor:(NSColor *)color
{
    CGFloat alpha = color.alphaComponent;
    int max = 255;
    
    unsigned char red, green, blue;
    if (color.colorSpaceName == NSCalibratedWhiteColorSpace || color.colorSpaceName == NSDeviceWhiteColorSpace) {
        red = green = blue = (char)(color.whiteComponent * alpha * max);
    } else  {
        red = (unsigned char)(color.redComponent * alpha * max);
        green = (unsigned char)(color.greenComponent * alpha * max);
        blue = (unsigned char)(color.blueComponent * alpha * max);
    }
    
    unsigned char luxaforOperation[kLuxaforOperationSize];
    
    //report id
    luxaforOperation[0] = 0x0;
    //continious transition
    luxaforOperation[1] = 2;
    //all leds
    luxaforOperation[2] = 0xFF;
    //red color component
    luxaforOperation[3] = red;
    //green color component
    luxaforOperation[4] = green;
    //blue color component
    luxaforOperation[5] = blue;
    //transition speed
    luxaforOperation[6] = _transitionSpeed;
    
    [self performLuxoforOperation:luxaforOperation];
}

- (void)performLuxoforOperation:(unsigned char *)luxoforOperation
{
    hid_device *hidHandle = hid_open(kLuxaforVendorId, kLuxaforProductId, NULL);
    
    if (hidHandle != NULL) {
        hid_write(hidHandle, luxoforOperation, kLuxaforOperationSize);
        hid_close(hidHandle);
    }
}

- (BOOL)connected
{
    hid_device *hidHandle = hid_open(kLuxaforVendorId, kLuxaforProductId, NULL);
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
