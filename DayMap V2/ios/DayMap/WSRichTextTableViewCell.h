//
//  WSRichTextTableViewCell.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/23/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Task+Additions.h"

static NSString * const WSRichTextTableViewCellResignedObserverNotification = @"WSRichTextTableViewCellResignedObserverNotification";

@interface WSRichTextTableViewCell : UITableViewCell <UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic) BOOL shouldItalicize;
@property (nonatomic) CGFloat editingOffset;
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIButton *completedButton;

@property (nonatomic, strong) AbstractTask *task;
@property (nonatomic, strong) NSDate *day;

- (IBAction)toggleCompleted:(id)sender;

- (void)editTitle;

@end
