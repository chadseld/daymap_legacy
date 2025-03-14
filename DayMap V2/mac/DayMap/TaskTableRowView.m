//
//  TaskTableRowView.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/10/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "TaskTableRowView.h"
#import "NSColor+WS.h"

@implementation TaskTableRowView

- (NSTableViewDraggingDestinationFeedbackStyle)draggingDestinationFeedbackStyle {
	return NSTableViewDraggingDestinationFeedbackStyleGap;
}

- (void)drawSelectionInRect:(NSRect)rect {
	if (self.selected && self.selectionHighlightStyle == NSTableViewSelectionHighlightStyleRegular) {
		
		if (self.window.isKeyWindow && self.emphasized) {
			[[NSColor selectedControlColor] set];
		}
		else {
			[[NSColor secondarySelectedControlColor] set];
		}
		
		NSRectFillUsingOperation(rect, NSCompositeCopy);
	}
	else {
		[super drawSelectionInRect:rect];
	}
}

//- (BOOL)isOpaque {
//	return YES;
//}
//
//- (void)drawBackgroundInRect:(NSRect)dirtyRect {
//	[[NSColor underPageBackgroundColor] set];
//	NSRectFill(dirtyRect);
//}
@end
