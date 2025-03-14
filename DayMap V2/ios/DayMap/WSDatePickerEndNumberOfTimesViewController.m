//
//  WSDatePickerEndNumberOfTimesViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSDatePickerEndNumberOfTimesViewController.h"

@interface WSDatePickerEndNumberOfTimesViewController ()

@end

@implementation WSDatePickerEndNumberOfTimesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"End After";
	
	self.timesTextField.text = [NSString stringWithFormat:@"%ld", (long)self.scheduledDate.repeatEndAfterCount];
	self.stepper.value = self.scheduledDate.repeatEndAfterCount;
}

- (void)viewDidUnload {
    [self setTimesTextField:nil];
	[self setStepper:nil];
    [super viewDidUnload];
}

- (IBAction)timesChanged:(id)sender {
	NSInteger value = [self.timesTextField.text integerValue];;
	if (value <= 0) {
		value = 1;
	}
	self.scheduledDate.repeatEndAfterCount = value;
	self.stepper.value = self.scheduledDate.repeatEndAfterCount;
	
	[self.delegate datePickerControllerDidChangeEndAfterDateEndAfterCount:self.scheduledDate];
}

- (IBAction)stepperChanged:(id)sender {
	self.scheduledDate.repeatEndAfterCount = self.stepper.value;
	self.timesTextField.text = [NSString stringWithFormat:@"%ld", (long)self.scheduledDate.repeatEndAfterCount];
	
	[self.delegate datePickerControllerDidChangeEndAfterDateEndAfterCount:self.scheduledDate];
}

@end
