//
//  MonthView.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "MonthView.h"
#import "NSColor+WS.h"

@implementation MonthView

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			[self setNeedsLayout:YES];
			[self resizeSubviewsWithOldSize:self.bounds.size];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)isOpaque {
	return YES;
}

- (BOOL)isFlipped {
	return YES;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	CGFloat kLeftRightMargin = 1;
	CGFloat kIntercellTopBottomMargin = 1;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
//		kLeftRightMargin = 2;
//		kIntercellTopBottomMargin = 2;
	}
	
	const CGFloat kDaysInWeek = 7.0;
	NSInteger numberOfWeeks = self.subviews.count / kDaysInWeek;
	
	CGFloat dayWidth = self.bounds.size.width / kDaysInWeek;
	CGFloat dayHeight = self.bounds.size.height / numberOfWeeks;
	
	for (NSInteger week = 0; week < numberOfWeeks; week++) {
		for (NSInteger day = 0; day < kDaysInWeek; day++) {
			NSView *dayView = self.subviews[week * (NSInteger)kDaysInWeek + day];
			
			NSRect frame = NSZeroRect;
			frame.origin = NSMakePoint(floor(day * dayWidth) + kLeftRightMargin, floor(week * dayHeight));
			frame.size = NSMakeSize(floor((day + 1) * dayWidth) - frame.origin.x, floor((week + 1) * dayHeight) - frame.origin.y - kIntercellTopBottomMargin);
			
			if (week == numberOfWeeks - 1) {
				frame.size.height = NSMaxY(self.bounds) - frame.origin.y - kIntercellTopBottomMargin;

			}
			if (day == kDaysInWeek - 1) {
				frame.size.width = NSMaxX(self.bounds) - frame.origin.x - kLeftRightMargin;
			}
			
			[dayView setFrame:frame];
		}
	}
	
	// Update hover scroll views (these are not subviews of self, but siblings)
	NSInteger amount = MAX(7, MIN(15, self.frame.size.height / 25));
	NSRect topRect, remainderRect, bottomRect;
	NSDivideRect(self.frame, &topRect, &remainderRect, amount, NSMaxYEdge);
	[self.topHoverScrollView setFrame:topRect];
	NSDivideRect(self.frame, &bottomRect, &remainderRect, amount, NSMinYEdge);
	[self.bottomHoverScrollView setFrame:bottomRect];
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if ([event deltaX] < 0) { // Right
		[self.delegate monthViewDidSwipeBackward:self];
	}
	else if ([event deltaX] > 0) { // Left
		[self.delegate monthViewDidSwipeForward:self];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent {
	[self.delegate monthViewDidScrollWheel:theEvent];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor dayMapCalendarDividerColor] set];
	NSRectFill(dirtyRect);
}

@end
