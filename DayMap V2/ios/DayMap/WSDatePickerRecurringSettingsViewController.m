//
//  WSDatePickerRecurringSettingsViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSDatePickerRecurringSettingsViewController.h"
#import "RecurrenceRule+Additions.h"
#import "NSDate+WS.h"
#import "WSDatePickerEndDateViewController.h"
#import "WSDatePickerEndNumberOfTimesViewController.h"


@interface WSDatePickerRecurringSettingsViewController ()

@end

@implementation WSDatePickerRecurringSettingsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Repeat";

	((UITableView *)self.view).backgroundView = nil;
	
	[self updateCheckmarks];
}

- (void)updateCheckmarks {
	self.frequencyNoneCell.accessoryType = (self.scheduledDate.repeatFrequency == -1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	self.frequencyDayCell.accessoryType = (self.scheduledDate.repeatFrequency == DMRecurrenceFrequencyDaily ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	self.frequencyWeekCell.accessoryType = (self.scheduledDate.repeatFrequency == DMRecurrenceFrequencyWeekly ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	self.frequencyBiweekCell.accessoryType = (self.scheduledDate.repeatFrequency == DMRecurrenceFrequencyBiweekly ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	self.frequencyMonthCell.accessoryType = (self.scheduledDate.repeatFrequency == DMRecurrenceFrequencyMonthly ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	self.frequencyYearCell.accessoryType = (self.scheduledDate.repeatFrequency == DMRecurrenceFrequencyYearly ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	
	if (self.scheduledDate.repeatFrequency == -1) {
		self.endDateCell.accessoryType = UITableViewCellAccessoryNone;
		self.endNumberCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else {
		self.endDateCell.accessoryType = (self.scheduledDate.repeatEndAfterDate != nil ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
		self.endNumberCell.accessoryType = (self.scheduledDate.repeatEndAfterCount > 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
	}
}


#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UILabel *label = [UILabel new];
	if (0 == section) {
		label.text = @"  Repeat";
	}
	if (1 == section) {
		label.text = @"  End After";
	}
	
    label.font = [UIFont boldSystemFontOfSize:16];
    label.backgroundColor = [UIColor clearColor];
	label.shadowOffset = CGSizeMake(0, 1);
	return label;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[tableView indexPathForCell:self.frequencyNoneCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = -1;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	if ([[tableView indexPathForCell:self.frequencyDayCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyDaily;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	if ([[tableView indexPathForCell:self.frequencyWeekCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyWeekly;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	if ([[tableView indexPathForCell:self.frequencyBiweekCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyBiweekly;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	if ([[tableView indexPathForCell:self.frequencyMonthCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyMonthly;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	if ([[tableView indexPathForCell:self.frequencyYearCell] isEqual:indexPath]) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyYearly;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}
	
//	if ([[tableView indexPathForCell:self.endDateCell] isEqual:indexPath]) {
//		if (-1 == self.repeatFrequency) {
//			self.repeatFrequency = DMRecurrenceFrequencyDaily;
//			[self.delegate datePickerController:self didChangeRepeatFrequency:self.repeatFrequency];
//		}
//		
//		self.endAfterCount = 0;
//		if (nil == self.endAfterDate) {
//			self.endAfterDate = [NSDate today];
//		}
//		[self.delegate datePickerController:self didChangeEndAfterDate:self.endAfterDate endAfterCount:self.endAfterCount];
//	}
//	if ([[tableView indexPathForCell:self.endNumberCell] isEqual:indexPath]) {
//		if (-1 == self.repeatFrequency) {
//			self.repeatFrequency = DMRecurrenceFrequencyDaily;
//			[self.delegate datePickerController:self didChangeRepeatFrequency:self.repeatFrequency];
//		}
//		
//		self.endAfterDate = nil;
//		if (self.endAfterCount <= 0) {
//			self.endAfterCount = 3;
//		}
//		[self.delegate datePickerController:self didChangeEndAfterDate:self.endAfterDate endAfterCount:self.endAfterCount];
//	}
	
	[tableView selectRowAtIndexPath:0 animated:YES scrollPosition:NO];
	[self updateCheckmarks];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	id viewController = [segue destinationViewController];
	[viewController setValue:self.delegate forKey:@"delegate"];
	[viewController setValue:self.scheduledDate forKey:@"scheduledDate"];

	if (-1 == self.scheduledDate.repeatFrequency) {
		self.scheduledDate.repeatFrequency = DMRecurrenceFrequencyDaily;
		[self.delegate datePickerControllerDidChangeRepeatFrequency:self.scheduledDate];
	}

	if ([viewController isKindOfClass:[WSDatePickerEndDateViewController class]]) {
		self.scheduledDate.repeatEndAfterCount = 0;
		if (nil == self.scheduledDate.repeatEndAfterDate) {
			self.scheduledDate.repeatEndAfterDate = [[[NSDate today]
													 dateByAddingWeeks:1] dateQuantizedToDay];
		}
	}
	else if([viewController isKindOfClass:[WSDatePickerEndNumberOfTimesViewController class]]) {
		self.scheduledDate.repeatEndAfterDate = nil;
		if (self.scheduledDate.repeatEndAfterCount <= 0) {
			self.scheduledDate.repeatEndAfterCount = 3;
		}
	}
	[self.delegate datePickerControllerDidChangeEndAfterDateEndAfterCount:self.scheduledDate];
	[self updateCheckmarks];
}

- (void)viewDidUnload {
	[self setFrequencyNoneCell:nil];
	[self setFrequencyDayCell:nil];
	[self setFrequencyWeekCell:nil];
	[self setFrequencyMonthCell:nil];
	[self setFrequencyYearCell:nil];
	[self setEndDateCell:nil];
	[self setEndNumberCell:nil];
	[super viewDidUnload];
}

@end
