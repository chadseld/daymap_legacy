//
//  TaskTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Task.h"

@interface TaskTableCellView : NSTableCellView <NSPopoverDelegate> 

@property (nonatomic, strong) Task *task;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (nonatomic, readonly) NSColor *textColor;
@property (nonatomic, readonly) CGFloat fontSize;
@property (nonatomic, readonly) NSBezierPath *projectColorPath;
@property (nonatomic, strong) NSDate *day;

- (void)showPopover;
- (void)updateToolTip;

@end