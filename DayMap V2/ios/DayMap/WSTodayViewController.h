//
//  WSTodayViewController.h
//  DayMap
//
//  Created by Jonathan Huggins on 4/3/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WSAbstractTaskTableViewController.h"

#define kSectionHeaderHeight 40

@class DayMapManagedObjectContext;

@interface WSTodayViewController : WSAbstractTaskTableViewController

@property (strong, nonatomic) IBOutlet UIView *tableHeaderView;

@property (strong, nonatomic) IBOutlet UILabel *dayOfWeekName;
@property (strong, nonatomic) IBOutlet UILabel *dayNumber;
@property (nonatomic, strong) NSCalendar *currentCalendar;

- (void) insertNewObject;
- (UIView *)headerViewForDate:(NSDate*)day;

@property (nonatomic, strong) NSDate *today;

@end
