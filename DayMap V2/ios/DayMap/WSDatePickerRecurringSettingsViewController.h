//
//  WSDatePickerRecurringSettingsViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSDatePickerViewController.h"


@interface WSDatePickerRecurringSettingsViewController : UITableViewController

@property (nonatomic, assign) id <WSDatePickerControllerDelegate> delegate;
@property (nonatomic, strong) WSDatePickerScheduledDate *scheduledDate;

@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyNoneCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyDayCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyWeekCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyBiweekCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyMonthCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *frequencyYearCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endDateCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endNumberCell;

@end
