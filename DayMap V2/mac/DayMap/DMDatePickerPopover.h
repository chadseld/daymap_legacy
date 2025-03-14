//
//  DMDatePickerPopover.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/17/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMDatePickerPopover : NSPopover

@property (readonly) NSDatePicker *datePicker;

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge startDate:(NSDate *)startDate changeHandler:(void (^)(NSDate *date))changeHandler;

@end
