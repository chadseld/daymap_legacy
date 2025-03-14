//
//  NSDate+WS.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/19/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "NSDate+WS.h"

@implementation NSDate (NSDate_WS)
NSCalendar* GMTCalendar(void);
NSCalendar* localCalendar(void);

NSCalendar* GMTCalendar(void) {
	static NSCalendar *calendar = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		calendar = [NSCalendar currentCalendar];
		calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	});
	return calendar;
}

NSCalendar* localCalendar(void) {
	static NSCalendar *calendar = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		calendar = [NSCalendar currentCalendar];
		calendar.timeZone = [NSTimeZone localTimeZone];
	});
	return calendar;
}

- (NSDate *)beginningOfWeek {
	NSDate *beginningOfWeek = nil;
	
	BOOL success = [GMTCalendar() rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&beginningOfWeek
							interval:NULL forDate:self];
	if (!success) {
		return [self dateQuantizedToSunday];
	}
	return beginningOfWeek;
}

- (NSDate *)beginningOfMonth {
	NSDate *beginningOfMonth = nil;
	
	BOOL success = [GMTCalendar() rangeOfUnit:NSCalendarUnitMonth startDate:&beginningOfMonth
								 interval:NULL forDate:self];
	if (!success) {
		return [self dateQuantizedToMonth];
	}
	return beginningOfMonth;
}

- (NSDate *)dateQuantizedToMonth {
    NSDateComponents *components = [GMTCalendar() components:
                                    NSCalendarUnitYear |
                                    NSCalendarUnitMonth
                                          fromDate:self];
    NSDate *month = [GMTCalendar() dateFromComponents:components];
    return month;
}

- (NSDate *)dateQuantizedToSunday
{
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [GMTCalendar() components:NSCalendarUnitWeekday
												 fromDate:self];
	
	/*
	 Create a date components to represent the number of days to subtract from the current date.
	 The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today is Sunday, subtract 0 days.)
	 */
	NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
	[componentsToSubtract setDay: 0 - ([weekdayComponents weekday] - 1)];
	
	NSDate *beginningOfWeek = [GMTCalendar() dateByAddingComponents:componentsToSubtract
												   toDate:self
												  options:0];
	
	/*
	 Optional step:
	 beginningOfWeek now has the same hour, minute, and second as the original date (today).
	 To normalize to midnight, extract the year, month, and day components and create a new date from those components.
	 */
	return [beginningOfWeek dateQuantizedToDay];
}

+ (NSDate *)today {
    NSDateComponents *components = [localCalendar() components:
                                    NSCalendarUnitYear |
                                    NSCalendarUnitMonth |
                                    NSCalendarUnitDay
                                          fromDate:[NSDate date]];

	return [GMTCalendar() dateFromComponents:components];
}

- (NSDate *)dateQuantizedToDay
{
    NSDateComponents *components = [GMTCalendar() components:
                                    NSCalendarUnitYear |
                                    NSCalendarUnitMonth |
                                    NSCalendarUnitDay
                                          fromDate:self];
    NSDate *day = [GMTCalendar() dateFromComponents:components];
    return day;
}

- (NSDate *)dateByAddingDays:(NSInteger)days
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:days];
	NSDate *day = [GMTCalendar() dateByAddingComponents:components toDate:self options:0];
	return day;
}

- (NSDate *)dateByAddingWeeks:(NSInteger)weeks
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setWeekOfYear:weeks];
	NSDate *week = [GMTCalendar() dateByAddingComponents:components toDate:self options:0];
	return week;
}

- (NSDate *)dateByAddingMonths:(NSInteger)months
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setMonth:months];
	NSDate *month = [GMTCalendar() dateByAddingComponents:components toDate:self options:0];
	return month;
}

- (NSDate *)dateByAddingYears:(NSInteger)years
{
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setYear:years];
	NSDate *year = [GMTCalendar() dateByAddingComponents:components toDate:self options:0];
	return year;
}

- (NSDate *)dateInCurrentWeek {
	NSDate *currentWeek = [[NSDate date] dateQuantizedToSunday];
	NSDateComponents *weekdayComponents = [GMTCalendar() components:NSCalendarUnitWeekday
												 fromDate:self];
	return [currentWeek dateByAddingDays:[weekdayComponents weekday] - 1];
}

@end
