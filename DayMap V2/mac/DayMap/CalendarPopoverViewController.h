//
//  CalendarPopoverViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/6/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CalendarViewController;

@interface CalendarPopoverViewController : NSViewController <NSDatePickerCellDelegate, NSPopoverDelegate>

@property (nonatomic, strong) NSPopover *popover;
@property (nonatomic, strong) CalendarViewController *calendarViewController;
+ (CalendarPopoverViewController *)calendarPopoverViewController;

@end
