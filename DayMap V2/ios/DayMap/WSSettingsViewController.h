//
//  WSSettingsViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/5/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSSettingsViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UISwitch *toggleiCloudButton;
- (IBAction)toggleiCloud:(id)sender;
@property (weak, nonatomic) IBOutlet UITableViewCell *aboutTableCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *supportTableCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *overDueCell;
@property (strong, nonatomic) IBOutlet UILabel *sliderLabel;
@property (strong, nonatomic) IBOutlet UISlider *pastDateFilterSlider;
- (IBAction)fiterDateChanged:(id)sender;
- (IBAction)changeDisplayValue:(id)sender;
@end
