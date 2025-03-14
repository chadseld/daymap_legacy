//
//  DMDatePickerPopover.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/17/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import "DMDatePickerPopover.h"

@interface DMDatePickerViewController : NSViewController <NSPopoverDelegate>

@property (strong) NSDatePicker *datePicker;
@property (nonatomic, copy) void (^changeHandler)(NSDate *date);

@end

@implementation DMDatePickerViewController

- (void)loadView {
	self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 138, 148)];

	self.datePicker = [[NSDatePicker alloc] initWithFrame:self.view.bounds];
	self.datePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	self.datePicker.datePickerStyle = NSClockAndCalendarDatePickerStyle;
	self.datePicker.datePickerMode = NSSingleDateMode;
	self.datePicker.datePickerElements = NSYearMonthDayDatePickerElementFlag;
	self.datePicker.target = self;
	self.datePicker.action = @selector(datePickerChanged:);

	[self.view addSubview:self.datePicker];
}

- (void)datePickerChanged:(NSDatePicker *)sender {
	self.changeHandler(self.datePicker.dateValue);
}

- (void)popoverWillClose:(NSNotification *)notification {
	self.changeHandler(self.datePicker.dateValue);
}

- (void)popoverDidClose:(NSNotification *)notification {
	NSPopover *popover = [notification object];
	popover.contentViewController = nil;
}

- (void)popoverDidShow:(NSNotification *)notification {
	self.changeHandler(self.datePicker.dateValue);
}

@end


@implementation DMDatePickerPopover

- (void)showRelativeToRect:(NSRect)positioningRect ofView:(NSView *)positioningView preferredEdge:(NSRectEdge)preferredEdge startDate:(NSDate *)startDate changeHandler:(void (^)(NSDate *date))changeHandler {

	self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	self.behavior = NSPopoverBehaviorTransient;
	self.animates = YES;

	DMDatePickerViewController *viewController = [[DMDatePickerViewController alloc] init];
	[viewController view];
	viewController.changeHandler = changeHandler;
	viewController.datePicker.dateValue = startDate;
	self.contentViewController = viewController;
	self.delegate = viewController;

	[super showRelativeToRect:positioningRect ofView:positioningView preferredEdge:preferredEdge];
}

- (NSDatePicker *)datePicker {
	return ((DMDatePickerViewController *)self.contentViewController).datePicker;
}

//- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate **)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval
//{
//    *proposedDateValue = [*proposedDateValue beginningOfWeek];
//	NSDate *endOfWeek = [*proposedDateValue dateByAddingDays:7];
//
//	*proposedTimeInterval = [endOfWeek timeIntervalSinceDate:*proposedDateValue] - 1; // one week (minus one second, so we don't overlap into the next week)
//}

@end
