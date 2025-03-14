//
//  Task+Additions.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "RecurrenceRule.h"

/*!
Copied from EKRecurrenceFrequency
 */
typedef enum {
    DMRecurrenceFrequencyDaily = 0,
    DMRecurrenceFrequencyWeekly,
    DMRecurrenceFrequencyMonthly,
    DMRecurrenceFrequencyYearly,
	DMRecurrenceFrequencyBiweekly
} DMRecurrenceFrequency;


@interface RecurrenceRule (Additions)

+ (RecurrenceRule *)recurrenceRule;

- (BOOL)recursAtDate:(NSDate *)date;

// Completions
- (BOOL)isCompletedAtDate:(NSDate *)date baseCompletion:(NSInteger)baseCompletion partial:(BOOL *)outPartial;
- (void)setCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial;
- (void)toggleCompletedAtDate:(NSDate *)date baseCompletion:(NSInteger)baseCompletion partial:(BOOL)setPartial;
- (void)setUncompletedAtDate:(NSDate *)date;
- (void)clearCompletions;

// Exceptions
- (BOOL)hasExceptionForDate:(NSDate *)date;
- (void)addExceptionForDate:(NSDate *)date;
- (void)clearExceptions;

// Sorting
- (NSManagedObject *)sortIndexForDate:(NSDate *)date;
- (NSInteger)sortIndexInDayForDate:(NSDate *)date;
- (void)setSortIndexInDay:(NSInteger)sortIndexInDay forDate:(NSDate *)date;

- (NSString *)simpleStringDescription;

@end