//
//  WSModernSplitView.m
//  DayMap
//
//  Created by Chad Seldomridge on 9/8/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WSModernSplitView.h"
#import "NSColor+WS.h"

@implementation WSModernSplitView

- (BOOL)isOpaque {
	return YES;
}

- (void)drawDividerInRect:(NSRect)dividerRect
{
	[[NSColor dayMapDividerColor] set];
	NSRectFill(dividerRect);
	
	const CGFloat dotSize = 2;
	CGRect dotRect = NSMakeRect(NSMinX(dividerRect) + floor((dividerRect.size.width - (5 * dotSize)) / 2), NSMinY(dividerRect) + floor((dividerRect.size.height - dotSize) / 2), 5 * dotSize, dotSize);
	
	[[NSColor whiteColor] set];
	NSRectFill(dotRect);
}

- (CGFloat)dividerThickness {
	return 6;//3;
}

@end
