//
//  WSSolidModernButton.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/31/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WSSolidModernButton.h"
#import "NSColor+WS.h"

@implementation WSSolidModernButtonCell

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setTextColor:[NSColor dayMapLightTextColor]];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	NSRect trackRect = NSInsetRect(NSIntegralRect(frame), 2.5, 2.5);
	NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
	[track setLineWidth:1];


	if (self.isHighlighted) {
		[[[NSColor dayMapActionColor] darkerColor:0.3] set];
		[track fill];
	}
	else {
		[[NSColor dayMapActionColor] set];
		[track fill];
	}

	[[NSColor colorWithDeviceWhite:0.95 alpha:1] set];
	[track stroke];
}

@end

@implementation WSSolidModernButton

+ (Class)cellClass
{
    return [WSSolidModernButtonCell class];
}

@end
