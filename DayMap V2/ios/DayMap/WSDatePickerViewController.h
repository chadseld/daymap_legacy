//
//  WSDatePickerViewController.h
//  DayMap
//
//  Created by Jonathan Huggins on 4/28/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSDatePickerScheduledDate : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic) NSInteger repeatEndAfterCount;
@property (nonatomic, strong) NSDate * repeatEndAfterDate;
@property (nonatomic) NSInteger repeatFrequency;
@property (nonatomic) NSInteger repeatInterval;

@end


@protocol WSDatePickerControllerDelegate
- (void)datePickerControllerDidPickDate:(WSDatePickerScheduledDate *)scheduledDate;
- (void)datePickerControllerDidChangeRepeatFrequency:(WSDatePickerScheduledDate *)scheduledDate;
- (void)datePickerControllerDidChangeEndAfterDateEndAfterCount:(WSDatePickerScheduledDate *)scheduledDate;
@end


@interface WSDatePickerViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, assign) id <WSDatePickerControllerDelegate> delegate;
@property (nonatomic, strong) WSDatePickerScheduledDate *scheduledDate;

- (IBAction)clear:(id)sender;
- (IBAction)dateChanged:(id)sender;

@end