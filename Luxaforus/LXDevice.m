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

#define kLuxaforOperationSetRedColor        ((unsigned char *)"\0\0R")
#define kLuxaforOperationSetGreenColor      ((unsigned char *)"\0\0G")
#define kLuxaforOperationSetBlueColor       ((unsigned char *)"\0\0B")
#define kLuxaforOperationSetCyanColor       ((unsigned char *)"\0\0C")
#define kLuxaforOperationSetMagentaColor    ((unsigned char *)"\0\0M")
#define kLuxaforOperationSetYellowColor     ((unsigned char *)"\0\0Y")
#define kLuxaforOperationSetWhiteColor      ((unsigned char *)"\0\0W")
#define kLuxaforOperationSetBlackColor      ((unsigned char *)"\0\0O")

#define kLuxaforOperationSetPoductivityOn   ((unsigned char *)"\0\nE")
#define kLuxaforOperationSetPoductivityOff  ((unsigned char *)"\0\nD")

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
    if (CGColorGetNumberOfComponents(color) == 4) {
        
        _color = color;
        
        const CGFloat *components = CGColorGetComponents(color);
        char red = (char)(components[0] * 255);
        char green = (char)(components[1] * 255);
        char blue = (char)(components[2] * 255);
        
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
}

- (void)setProductivityModeEnabled:(BOOL)productivityModeEnabled
{
    _productivityModeEnabled = productivityModeEnabled;
    
    if (productivityModeEnabled) {
        [self performLuxoforOperation:kLuxaforOperationSetBlackColor];
        [self performLuxoforOperation:kLuxaforOperationSetPoductivityOn];
        
    } else {
        [self performLuxoforOperation:kLuxaforOperationSetPoductivityOff];
        [self performLuxoforOperation:kLuxaforOperationSetBlackColor];
    }
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
    
    if (hidHandle != NULL) {
        hid_close(hidHandle);
    }
    
    return connected;
}

- (void)dealloc
{
    hid_exit();
}

@end
