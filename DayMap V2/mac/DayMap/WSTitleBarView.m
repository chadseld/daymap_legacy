//
//  WSTitleBarView.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/24/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import "WSTitleBarView.h"
#import "NSColor+WS.h"

@implementation WSTitleBarView {
}

- (BOOL)isFlipped {
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
	// Border Path
	NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:self.bounds];

	// Gradient
	NSGradient *gradient;
	if ([self.window isKeyWindow]) {
		NSColor *baseTitleBarGradientColor = [NSColor colorWithDeviceWhite:0.93 alpha:1];
		gradient = [[NSGradient alloc] initWithStartingColor:[baseTitleBarGradientColor lighterColor:0.03] endingColor:[baseTitleBarGradientColor darkerColor:0.03]];
		[gradient drawInBezierPath:borderPath angle:270];
	}
	else {
		NSColor *baseTitleBarGradientColor = [NSColor colorWithDeviceWhite:0.93 alpha:1];
		gradient = [[NSGradient alloc] initWithStartingColor:[baseTitleBarGradientColor lighterColor:0.04] endingColor:baseTitleBarGradientColor];
	}
	[gradient drawInBezierPath:borderPath angle:270];
}

@end
