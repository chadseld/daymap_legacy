//
//  WeekView.m
//  DayMap
//
//  Created by Chad Seldomridge on 7/6/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WeekView.h"
#import "NSDate+WS.h"
#import "NSColor+WS.h"

@implementation WeekView

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

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
	CGFloat margin = 1;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
//		margin = 2;
	}
	NSInteger viewCount = [self subviews].count;
    CGFloat width = self.bounds.size.width / [self subviews].count;
    CGFloat height = self.bounds.size.height;

	for (NSInteger i = 0; i < viewCount; i++) {
		NSView *view = [[self subviews] objectAtIndex:i];
		CGFloat x = floor(i * width) + margin;
		CGFloat dx = (floor((i + 1) * width) + margin) - x - margin;
		if (i == viewCount - 1) {
			dx = NSMaxX(self.bounds) - x - margin;
		}

		CGRect frame = NSIntegralRect(NSMakeRect(x, 0, dx, height));
        [view setFrame:frame];
    }
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if ([event deltaX] < 0) { // Right
		[self.delegate weekViewDidSwipeBackward:self];
	}
	else if ([event deltaX] > 0) { // Left
		[self.delegate weekViewDidSwipeForward:self];
	}
}

- (void)scrollWheel:(NSEvent *)theEvent {
	[self.delegate weekViewDidScrollWheel:theEvent];
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor dayMapCalendarDividerColor] set];
	NSRectFill(dirtyRect);
}

@end
