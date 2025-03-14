//
//  WeekViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WeekView.h"
#import "WSCalendarRangeViewController.h"
#import "HoverScrollView.h"

@interface WeekViewController : WSCalendarRangeViewController <WeekViewDelegate, HoverScrollViewDelegate>

+ (WeekViewController *)weekViewController;
@property (weak) IBOutlet HoverScrollView *leftHoverView;
@property (weak) IBOutlet HoverScrollView *rightHoverView;
@property (weak) IBOutlet WeekView *weekView;

@end
