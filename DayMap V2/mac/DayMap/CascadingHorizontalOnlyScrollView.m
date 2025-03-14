//
//  CascadingHorizontalOnlyScrollView.m
//  DayMap
//
//  Created by Chad Seldomridge on 8/23/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "CascadingHorizontalOnlyScrollView.h"

@implementation CascadingHorizontalOnlyScrollView

//- (BOOL)isCompatibleWithResponsiveScrolling {
//	return NO;
//}

- (void)scrollWheel:(NSEvent *)event
{
    //	NSLog(@"dX = %f, dY = %f", event.scrollingDeltaX, event.scrollingDeltaY);
	if (fabs(event.scrollingDeltaX) < fabs(event.scrollingDeltaY)) {
		[[self nextResponder] scrollWheel:event];
	}
	else {
		[super scrollWheel:event];
	}
}

@end
