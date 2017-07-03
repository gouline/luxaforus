//
//  LXDevice.h
//  Luxafor-OSX
//
//  Created by Aigars Silavs on 12/04/15.
//  Copyright (c) 2015 draugiem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface LXDevice : NSObject

+ (LXDevice *)sharedInstance;

@property (nonatomic) CGColorRef color;
@property (nonatomic) char transitionSpeed;
@property (nonatomic) BOOL productivityModeEnabled;
@property (nonatomic) BOOL connected;

@end
