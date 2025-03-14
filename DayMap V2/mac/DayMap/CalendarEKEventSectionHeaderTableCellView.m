//
//  CalendarEKEventSectionHeaderTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarEKEventSectionHeaderTableCellView.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"
#import "MiscUtils.h"
#import <EventKit/EventKit.h>


@implementation CalendarEKEventSectionHeaderTableCellView {
	NSColor *_calendarColor;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
	self.titleLabel.font = [NSFont dayMapListFontOfSize:[self fontSize]];
}

- (CGFloat)fontSize {
	return [NSFont dayMapListFontSize];
}

- (NSColor *)textColor {
	return [NSColor dayMapDarkTextColor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			self.titleLabel.font = [NSFont dayMapListFontOfSize:[self fontSize]];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	// do nothing. Prevents system from changing color of text when selected.
}

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor dayMapEKEventsCalendarBackgroundColor] set];
	NSRectFill(dirtyRect);
}

@end
