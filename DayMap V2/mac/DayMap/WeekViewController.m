//
//  WeekViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WeekViewController.h"
#import "WeekDayView.h"
#import "NSDate+WS.h"


@interface WeekViewController () {
	NSMutableArray *_dayViews;
}

@end


@implementation WeekViewController

+ (WeekViewController *)weekViewController {
    id controller = [[self alloc] initWithNibName:@"WeekView" bundle:nil];
    return controller;
}

- (void)awakeFromNib {
	// Day views
    for (int i=0; i<7; i++) {
        WeekDayView *dayView = [[WeekDayView alloc] initWithFrame:NSZeroRect];
        [self.weekView addSubview:dayView];
    }
    _dayViews = [self.weekView.subviews mutableCopy];
}

- (void)weekViewDidSwipeForward:(WeekView *)weekView {
	[self.delegate calendarRangeForward:self];
}

- (void)weekViewDidSwipeBackward:(WeekView *)weekView {
	[self.delegate calendarRangeBack:self];
}

- (void)weekViewDidScrollWheel:(NSEvent *)event {
	[self.delegate calendarRange:self scrollWithEvent:event];
}

- (void)reloadData {
	NSDate *week = [self.dataSource calendarRangeStartDay:self];
    for (int i=0; i<7; i++) {
		WeekDayView *dayView = (WeekDayView *)[_dayViews objectAtIndex:i];
        dayView.day = [week dateByAddingDays:i];
    }
}

- (NSDate *)dayOfFirstResponder {
	// Subclass to implement
	NSResponder *firstResponder = self.view.window.firstResponder;
	if (![firstResponder isKindOfClass:[NSView class]]) {
		return nil;
	}
	
	for (int i=0; i<7; i++) {
		WeekDayView *dayView = (WeekDayView *)[_dayViews objectAtIndex:i];
		if ([(NSView *)firstResponder ancestorSharedWithView:dayView] == dayView) {
			return dayView.day;
		}
	}
	return nil;

}

- (void)makeViewWithDayFirstResponder:(NSDate *)day {
	day = [day dateQuantizedToDay];
	for (int i=0; i<7; i++) {
		WeekDayView *dayView = (WeekDayView *)[_dayViews objectAtIndex:i];
		if ([[dayView.day dateQuantizedToDay] isEqualToDate:day]) {
			[dayView makeFirstResponder];
			return;
		}
	}
}

- (void)hoverScrollViewIsHovering:(HoverScrollView *)hoverScrollView {
	if (self.leftHoverView == hoverScrollView) {
		[self.delegate calendarRangeBack:self];
	}
	if (self.rightHoverView == hoverScrollView) {
		[self.delegate calendarRangeForward:self];
	}
}

@end
