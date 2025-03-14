//
//  CalendarViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/11/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CalendarHeaderView.h"
#import "WeekSelectionWidget.h"
#import "DayMapManagedObjectContext.h"
#import "WeekViewController.h"
#import "MonthViewController.h"

@interface CalendarViewController : NSViewController <NSPopoverDelegate, WSCalendarRangeViewControllerDataSource, WSCalendarRangeViewControllerDelegate>

@property (nonatomic, assign) DMCalendarViewByMode calendarViewByMode;
@property (weak) IBOutlet CalendarHeaderView *calendarHeaderView;
@property (copy) NSDate *week;
@property (weak) IBOutlet WeekSelectionWidget *weekSelectionWidget;

@property (strong) WeekViewController *weekViewController;
@property (strong) MonthViewController *monthViewController;

- (IBAction)showCalendarPopover:(id)sender;
- (IBAction)forwardDateRange:(id)sender;
- (IBAction)backDateRange:(id)sender;
- (IBAction)showToday:(id)sender;

@end
