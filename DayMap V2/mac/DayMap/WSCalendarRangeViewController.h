//
//  WSCalendarProtocol.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WSCalendarRangeViewController;

@protocol WSCalendarRangeViewControllerDataSource

- (NSDate *)calendarRangeStartDay:(WSCalendarRangeViewController *)viewController;

@end


@protocol WSCalendarRangeViewControllerDelegate

- (void)calendarRangeForward:(WSCalendarRangeViewController *)viewController;
- (void)calendarRangeBack:(WSCalendarRangeViewController *)viewController;
- (void)calendarRange:(WSCalendarRangeViewController *)viewController showWeek:(NSDate *)week;
- (void)calendarRange:(WSCalendarRangeViewController *)viewController scrollWithEvent:(NSEvent *)event;

@end


@interface WSCalendarRangeViewController : NSViewController

@property (assign) IBOutlet NSObject<WSCalendarRangeViewControllerDelegate> *delegate;
@property (assign) IBOutlet NSObject<WSCalendarRangeViewControllerDataSource> *dataSource;

- (void)reloadData;
- (NSDate *)dayOfFirstResponder;
- (void)makeViewWithDayFirstResponder:(NSDate *)day;

@end

