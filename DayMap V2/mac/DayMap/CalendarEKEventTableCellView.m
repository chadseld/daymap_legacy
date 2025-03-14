//
//  CalendarEKEventTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarEKEventTableCellView.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"
#import "MiscUtils.h"
#import <EventKit/EventKit.h>


@implementation CalendarEKEventTableCellView {
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

- (NSColor *)textColor {
	return [NSColor dayMapDarkTextColor];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	// do nothing. Prevents system from changing color of text when selected.
}

- (void)updateTitle {
	static NSDateFormatter *timeFormatter;
	if (!timeFormatter) {
		timeFormatter = [[NSDateFormatter alloc] init];
		NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"j:mm a" options:0 locale:[NSLocale currentLocale]];
		formatString = [formatString stringByAppendingString:@" - "];
		[timeFormatter setDateFormat:formatString];
	}
	
	if (self.event.isAllDay) {
		self.titleLabel.stringValue = self.event.title;
	}
	else {
		self.titleLabel.stringValue = [[timeFormatter stringFromDate:self.event.startDate] stringByAppendingString:self.event.title];
	}
}

- (void)setEvent:(EKEvent *)event {
	_event = event;
	
	[self updateTitle];
	[self updateToolTip];
	_calendarColor = event.calendar.color;
}

- (void)updateToolTip {
	self.toolTip = [[self.event.title stringByAppendingString:@"\n----\nApple Calendar Event\nCalendar: "] stringByAppendingString:self.event.calendar.title];
}

- (void)showPopover
{
}

- (BOOL)isOpaque {
	return YES;
}

@end
