//
//  WSProjectColorPickerViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/16/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILColorPickerView.h"


@class WSProjectColorPickerViewController;
@protocol WSProjectColorPickerViewControllerDelegate
- (void)colorPickerController:(WSProjectColorPickerViewController *)controller didPickColor:(UIColor *)color;
@end

@interface WSProjectColorPickerViewController : UIViewController

@property (nonatomic, assign) id <WSProjectColorPickerViewControllerDelegate> delegate;
@property (nonatomic, strong) UIColor *color;
@property (weak, nonatomic) IBOutlet ILColorPickerView *colorPicker;
- (IBAction)doneButtonPressed:(id)sender;

@end
