//
//  WSDatePickerViewController.m
//  DayMap
//
//  Created by Jonathan Huggins on 4/28/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSDatePickerViewController.h"
#import "NSDate+WS.h"
#import "WSDatePickerRecurringSettingsViewController.h"


@implementation WSDatePickerScheduledDate

@end


@implementation WSDatePickerViewController

- (IBAction)clear:(id)sender {
	self.scheduledDate.date = nil;
//    [self.delegate datePickerControllerDidPickDate:nil];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)dateChanged:(id)sender {
	self.scheduledDate.date = [self.datePicker.date dateQuantizedToDay];
//	[self.delegate datePickerControllerDidPickDate:self.scheduledDate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Scheduled";
	// Do any additional setup after loading the view.

	self.datePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [self.datePicker setDate:self.scheduledDate.date];
//	[self.delegate datePickerControllerDidPickDate:self.scheduledDate];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

//- (void)setDate:(NSDate *)date {
//	_date = date;
//	self.datePicker.date = date;
//}
//
//- (NSDate *)date {
//	return [self.datePicker.date dateQuantizedToDay];
//}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.delegate datePickerControllerDidPickDate:self.scheduledDate];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	WSDatePickerRecurringSettingsViewController *viewController = (WSDatePickerRecurringSettingsViewController *)[segue destinationViewController];
	viewController.delegate = self.delegate;
	viewController.scheduledDate = self.scheduledDate;
}

@end
