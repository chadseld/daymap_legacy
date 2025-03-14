//
//  MonthViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WSCalendarRangeViewController.h"
#import "MonthView.h"
#import "MonthDayView.h"
#import "HoverScrollView.h"

@interface MonthViewController : WSCalendarRangeViewController <MonthViewDelegate, MonthDayViewDelegate, MonthDayViewDataSource, HoverScrollViewDelegate>

+ (MonthViewController *)monthViewController;

@property (weak) IBOutlet HoverScrollView *topHoverView;
@property (weak) IBOutlet HoverScrollView *bottomHoverView;
@property (weak) IBOutlet MonthView *monthView;

@end
