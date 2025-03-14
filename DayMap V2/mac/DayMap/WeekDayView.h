//
//  DayView.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/19/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WeekDayView : NSView <NSTableViewDelegate, NSTableViewDataSource> 

@property (nonatomic, strong) NSDate *day;

- (void)makeFirstResponder;

@end
