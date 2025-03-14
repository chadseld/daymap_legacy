//
//  WSDatePickerEndNumberOfTimesViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSDatePickerViewController.h"

@interface WSDatePickerEndNumberOfTimesViewController : UIViewController

@property (nonatomic, assign) id <WSDatePickerControllerDelegate> delegate;
@property (nonatomic, strong) WSDatePickerScheduledDate *scheduledDate;

@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UITextField *timesTextField;
- (IBAction)timesChanged:(id)sender;
- (IBAction)stepperChanged:(id)sender;

@end
