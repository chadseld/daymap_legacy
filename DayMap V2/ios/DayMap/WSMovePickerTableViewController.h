//
//  MovePickerTableViewController.h
//  DayMap
//
//  Created by Jonathan Huggins on 5/21/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSAbstractTaskTableViewController.h"
#import "WSDetailViewController.h"

@interface WSMovePickerTableViewController : WSAbstractTaskTableViewController

@property (strong, nonatomic) NSString *detailItemUUID;
@property (strong, nonatomic) WSDetailViewController *taskView;

@end
