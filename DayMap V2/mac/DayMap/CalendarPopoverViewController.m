//
//  CalendarPopoverViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/6/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarPopoverViewController.h"
#import "NSDate+WS.h"
#import "CalendarViewController.h"

@interface CalendarPopoverViewController ()

@property (weak) IBOutlet NSDatePicker *datePicker;

- (IBAction)datePicked:(id)sender;

@end


@implementation CalendarPopoverViewController

+ (CalendarPopoverViewController *)calendarPopoverViewController
{
    id controller = [[self alloc] initWithNibName:@"CalendarPopover" bundle:nil];
    return controller;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
	[self.calendarViewController removeObserver:self forKeyPath:@"week"context:nil];
}

- (void)awakeFromNib
{
	self.datePicker.timeZone = [NSTimeZone localTimeZone];
    [self.datePicker setDelegate:self];
    
    // Set the initial time interval to one week
    NSDate *date = nil;
    NSTimeInterval timeInterval = 0;
    [self datePickerCell:self.datePicker.cell validateProposedDateValue:&date timeInterval:&timeInterval];
    [self.datePicker setTimeInterval:timeInterval];
	self.datePicker.dateValue = [self gmtToLocal:self.calendarViewController.week];
}

- (void)setCalendarViewController:(CalendarViewController *)calendarViewController {
	[_calendarViewController removeObserver:self forKeyPath:@"week"context:nil];
	_calendarViewController = calendarViewController;
	[_calendarViewController addObserver:self forKeyPath:@"week" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == nil) {
		if ([keyPath isEqualToString:@"week"]) {
			[self.datePicker setDateValue:[self gmtToLocal:self.calendarViewController.week]];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (NSDate *)localToGMT:(NSDate *)localDate {
	NSCalendar *localCal = [NSCalendar currentCalendar];
	localCal.timeZone = [NSTimeZone localTimeZone];
	NSCalendar *gmtCal = [NSCalendar currentCalendar];
	gmtCal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	
	NSDateComponents *components = [localCal components:
									NSCalendarUnitYear |
									NSCalendarUnitMonth |
									NSCalendarUnitDay
											   fromDate:localDate];
	
	return [gmtCal dateFromComponents:components];
}

- (NSDate *)gmtToLocal:(NSDate *)gmtDate {
	NSCalendar *localCal = [NSCalendar currentCalendar];
	localCal.timeZone = [NSTimeZone localTimeZone];
	NSCalendar *gmtCal = [NSCalendar currentCalendar];
	gmtCal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	
	NSDateComponents *components = [gmtCal components:
									NSCalendarUnitYear |
									NSCalendarUnitMonth |
									NSCalendarUnitDay
											   fromDate:gmtDate];
	
	return [localCal dateFromComponents:components];
}

- (void)datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate **)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval
{
	if (nil == *proposedDateValue) {
		return;
	}
	
	NSDate *gmtDate = [self localToGMT:*proposedDateValue];
    gmtDate = [gmtDate beginningOfWeek];
	NSDate *endOfWeek = [gmtDate dateByAddingDays:7];

	*proposedDateValue = [self gmtToLocal:gmtDate];
	*proposedTimeInterval = [endOfWeek timeIntervalSinceDate:gmtDate] - 1; // one week (minus one second, so we don't overlap into the next week)
}

- (IBAction)datePicked:(id)sender {
	self.calendarViewController.week = [self localToGMT:self.datePicker.dateValue];
}

@end
