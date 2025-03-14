//
//  DMCompletedFilterPopoverViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/14/14.
//  Copyright (c) 2014 Whetstone Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMCompletedFilterPopoverViewController : NSViewController <NSPopoverDelegate>

+ (DMCompletedFilterPopoverViewController *)sharedController;
- (void)showFromView:(NSView *)view;
- (void)hide;

@end
