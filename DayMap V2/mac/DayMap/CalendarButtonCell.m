//
//  CalendarButtonCell.m
//  DayMap
//
//  Created by Chad Seldomridge on 2013-06-13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "CalendarButtonCell.h"
#import "NSColor+WS.h"
#import "MiscUtils.h"

@implementation CalendarButtonCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect unit = [controlView convertRectToBacking:NSMakeRect(0, 0, 1, 1)];
	if (unit.size.width > 1) {
		[super drawInteriorWithFrame:NSOffsetRect(cellFrame, 0, 1) inView:controlView];
	}
	else {
		[super drawInteriorWithFrame:cellFrame inView:controlView];
	}
}

@end
