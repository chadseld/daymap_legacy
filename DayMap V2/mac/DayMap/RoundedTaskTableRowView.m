//
//  RoundedTaskTableRowView.m
//  DayMap
//
//  Created by Chad Seldomridge on 8/1/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "RoundedTaskTableRowView.h"
#import "NSColor+WS.h"

@implementation RoundedTaskTableRowView

- (void)drawSelectionInRect:(NSRect)rect {
	if (self.selected && self.selectionHighlightStyle == NSTableViewSelectionHighlightStyleRegular) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 2, 1) xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
		if (self.window.isKeyWindow) {
			[[NSColor selectedControlColor] set];
		}
		else {
			[[NSColor secondarySelectedControlColor] set];
		}
		[path fill];
		//		[path setLineWidth:1];
		//		//[[NSColor colorWithDeviceRed:0.49 green:0.05 blue:0.07 alpha:1.0] set];
		//		[[NSColor brownColor] set];
		//		[path stroke];
		
		//		if (self.emphasized) { // different drawing when app inactive
		//		}
		//		else {
		//		}
	}
	else {
		[super drawSelectionInRect:rect];
	}
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 2, 1) xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
	[[NSColor dayMapBackgroundColor] set];
	[path fill];
}

- (BOOL)isOpaque {
	return NO;
}

@end
