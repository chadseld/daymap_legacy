//
//  CalendarEKEventSectionHeaderTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskTableCellView.h"
#import <EventKit/EKEvent.h>

@interface CalendarEKEventSectionHeaderTableCellView : NSTableCellView <NSPopoverDelegate>

@property (weak) IBOutlet NSTextField *titleLabel;
@property (nonatomic, readonly) NSColor *textColor;
@property (nonatomic, readonly) CGFloat fontSize;

@end