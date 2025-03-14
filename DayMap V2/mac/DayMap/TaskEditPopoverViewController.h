//
//  TaskEditPopoverViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/23/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Task.h"

@interface TaskEditPopoverViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, strong) Task *task;
@property (nonatomic, strong) NSPopover *popover;

@property (nonatomic, strong) NSAttributedString *attributedDetails;
@property (strong) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet NSButton *completedCheckbox;
@property (weak) IBOutlet NSDatePicker *scheduledDatePicker;
@property (weak) IBOutlet NSPopUpButton *repeatPopUpButton;
@property (weak) IBOutlet NSPopUpButton *endPopUpButton;
@property (weak) IBOutlet NSTextField *endNumberOfTimesTextField;
@property (weak) IBOutlet NSDatePicker *endDatePicker;
@property (weak) IBOutlet NSTextField *endTimesLabel;
@property (strong) NSDate *scheduledDate;
@property (strong) NSDate *endDate;
@property (weak) IBOutlet NSButton *expandButton;
@property (weak) IBOutlet NSTextField *repeatLabel;
@property (weak) IBOutlet NSTextField *endLabel;
@property (weak) IBOutlet NSScrollView *descriptionScrollView;
@property (weak) IBOutlet NSTextField *notesLabel;
@property (weak) IBOutlet NSLayoutConstraint *notesTopConstraint;

@property (nonatomic, strong) NSDate *shownForDay;

+ (TaskEditPopoverViewController *)taskEditPopoverViewController;

- (IBAction)done:(id)sender;
- (IBAction)toggleCompleted:(id)sender;
- (IBAction)repeatFrequencyChanged:(id)sender;
- (IBAction)endMenuChanged:(id)sender;
- (IBAction)clearScheduledDate:(id)sender;
- (IBAction)scheduleForToday:(id)sender;
- (IBAction)showDatePickerPopover:(NSButton *)sender;
- (IBAction)expand:(id)sender;

@end
