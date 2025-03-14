//
//  WSDatePickerEndDateViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSDatePickerEndDateViewController.h"
#import "NSDate+WS.h"

@interface WSDatePickerEndDateViewController ()

@end

@implementation WSDatePickerEndDateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"End Date";
	self.datePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	self.datePicker.date = self.scheduledDate.repeatEndAfterDate;
}

- (void)viewDidUnload {
	[self setDatePicker:nil];
	[super viewDidUnload];
}

- (IBAction)dateChanged:(id)sender {
	self.scheduledDate.repeatEndAfterDate = [self.datePicker.date dateQuantizedToDay];
	[self.delegate datePickerControllerDidChangeEndAfterDateEndAfterCount:self.scheduledDate];
}

@end
