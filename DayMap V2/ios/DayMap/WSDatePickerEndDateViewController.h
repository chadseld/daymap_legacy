//
//  WSDatePickerEndDateViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSDatePickerViewController.h"

@interface WSDatePickerEndDateViewController : UIViewController

@property (nonatomic, assign) id <WSDatePickerControllerDelegate> delegate;
@property (nonatomic, strong) WSDatePickerScheduledDate *scheduledDate;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
- (IBAction)dateChanged:(id)sender;

@end
