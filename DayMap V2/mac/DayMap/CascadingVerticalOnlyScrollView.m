//
//  CascadingVerticalOnlyScrollView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/8/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CascadingVerticalOnlyScrollView.h"

@implementation CascadingVerticalOnlyScrollView

//- (BOOL)isCompatibleWithResponsiveScrolling {
//	return NO;
//}

- (void)scrollWheel:(NSEvent *)event
{
//	NSLog(@"dX = %f, dY = %f", event.scrollingDeltaX, event.scrollingDeltaY);
	if (fabs(event.scrollingDeltaX) > fabs(event.scrollingDeltaY)) {
		[[self nextResponder] scrollWheel:event];
	}
	else {
		[super scrollWheel:event];
	}
}

@end
