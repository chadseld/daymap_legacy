//
//  NSDate+WS.h
//  DayMap
//
//  Created by Chad Seldomridge on 5/19/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_WS)

- (NSDate *)beginningOfWeek;
- (NSDate *)beginningOfMonth;
- (NSDate *)dateQuantizedToDay;
- (NSDate *)dateByAddingDays:(NSInteger)days;
- (NSDate *)dateByAddingWeeks:(NSInteger)weeks;
- (NSDate *)dateByAddingMonths:(NSInteger)months;
- (NSDate *)dateByAddingYears:(NSInteger)years;
- (NSDate *)dateInCurrentWeek;

+ (NSDate *)today;

@end
