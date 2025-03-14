//
//  LeatherSliderCell.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/27/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "LeatherSliderCell.h"
#import "MiscUtils.h"
#import "NSColor+WS.h"

@implementation LeatherSliderCell {
	NSImage *knobImage;
}
//
//- (void)drawKnob:(NSRect)knobRect
//{
//	if (!knobImage) {
//		knobImage = [NSImage imageNamed:@"sliderKnob"];
//	}
//	
//	[knobImage drawInRect:WSCenterRectInRect(NSMakeSize(11, 11), knobRect) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
//}
//
//- (CGFloat)knobThickness {
//	return 11;
//}
//
//- (void)drawBarInside:(NSRect)barRect flipped:(BOOL)flipped
//{
////	[[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:0.3] set];
////	NSRectFillUsingOperation(barRect, NSCompositeSourceOver);
//	
//
//	NSRect rect = NSMakeRect(barRect.origin.x, floor((barRect.size.height - 1) / 2.0), barRect.size.width, 1);
//	[[NSColor dayMapActionColor] set];
//	NSRectFill(rect);
//}

@end
