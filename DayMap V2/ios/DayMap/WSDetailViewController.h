//
//  WSDetailViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 1/24/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AbstractTask.h"
#import "WSAbstractTaskTableViewController.h"
#import "WSDatePickerViewController.h"
#import "WSProjectColorPickerViewController.h"

@interface WSDetailViewController : WSAbstractTaskTableViewController <WSDatePickerControllerDelegate, WSProjectColorPickerViewControllerDelegate>//<UISplitViewControllerDelegate>

@property (strong, nonatomic) NSString *detailItemUUID;
@property (nonatomic, strong) NSDate *shownForDay;
@property (strong, nonatomic) IBOutlet UIView *tableHeaderView;
@property (strong, nonatomic) IBOutlet UIView *taskDetailsView;
@property (strong, nonatomic) IBOutlet UIView *projectDetailsView;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *completedSwitch;
@property (strong, nonatomic) IBOutlet UITextView *detailTextView;
@property (strong, nonatomic) IBOutlet UIButton *scheduledDateButton;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *projectColorButton;
@property (strong, nonatomic) IBOutlet UIButton *moveButton;
@property (strong, nonatomic) IBOutlet UIButton *addTaskButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableHeaderHeightConstraint;

- (IBAction)competedSwitchChanged:(id)sender;
- (IBAction)scheduledDateButtonPressed:(id)sender;
- (IBAction)projectColorButtonPressed:(id)sender;
- (IBAction)nameEdited:(id)sender;
- (IBAction)hideKeyboard:(id)sender;

- (void)moveToTask:(NSString *)moveToTaskUUID;

@end
