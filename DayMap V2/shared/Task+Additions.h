//
//  Task+Additions.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "Task.h"

#define DMTaskTableViewDragDataType @"com.whetstone.daymap.task.uuid"

@interface Task (Additions)

+ (Task *)task;

#if !TARGET_OS_IPHONE
+ (void)placeTasks:(NSArray *)tasks onPasteboard:(NSPasteboard *)pboard fromDate:(NSDate *)fromDate;
+ (NSArray *)tasksFromPasteboard:(NSPasteboard *)pboard fromDate:(NSDate **)outFromDate;
+ (NSString *)utf8FormattedStringForTasks:(NSArray *)rootTasks;
#endif

+ (void)toggleCompleted:(NSArray *)tasks atDate:(NSDate *)date;
- (BOOL)isCompletedAtDate:(NSDate *)date partial:(BOOL *)outPartial;
- (void)setCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial;
- (void)toggleCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial;
- (void)setUncompletedAtDate:(NSDate *)date;

- (void)setScheduledDate:(NSDate *)scheduledDate handlingRecurrenceAtDate:(NSDate *)recurrenceDate;

- (NSInteger)sortIndexInDayForDate:(NSDate *)date;
- (void)setSortIndexInDay:(NSNumber *)sortIndexInDay forDate:(NSDate *)date;

- (NSString *)asHtml;
- (NSDate *)recurringEndDate;

@end
