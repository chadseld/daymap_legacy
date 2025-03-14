//
//  DMEventKitBridge.m
//  DayMap
//
//  Created by Chad Seldomridge on 6/20/14.
//  Copyright (c) 2014 Whetstone Apps. All rights reserved.
//

#import "DMEventKitBridge.h"

#import <EventKit/EKEvent.h>
#import <EventKit/EKEventStore.h>
#import <EventKit/EKCalendar.h>
#import "NSDate+WS.h"

@implementation DMEventKitBridge {
	EKEventStore *_eventStore;
	NSArray *_calendars;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_eventStore = [[EKEventStore alloc] init];
		[_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
			_calendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];

		}];

		
	}
	return self;
}

- (NSDate *)startOfLocalDay:(NSDate *)date {
	NSCalendar *cal = [NSCalendar currentCalendar];
	cal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	
	NSDateComponents *components = [cal components:
									NSCalendarUnitYear |
									NSCalendarUnitMonth |
									NSCalendarUnitDay
										  fromDate:date];
	
	cal = [NSCalendar currentCalendar];
	cal.timeZone = [NSTimeZone defaultTimeZone];

	NSDate *day = [cal dateFromComponents:components];
	return day;
}

- (NSDate *)addDays:(NSInteger)days toDay:(NSDate *)day {
	NSCalendar *cal = [NSCalendar currentCalendar];
	cal.timeZone = [NSTimeZone defaultTimeZone];
	
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[components setDay:days];
	NSDate *newDay = [cal dateByAddingComponents:components toDate:day options:0];
	return newDay;
}

- (NSArray *)eventsForDay:(NSDate *)date {
	date = [self startOfLocalDay:date];
	NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:date endDate:[self addDays:1 toDay:date] calendars:_calendars];
	NSArray *events = [_eventStore eventsMatchingPredicate:predicate];
	if (!events) {
		return @[];
	}

	NSSortDescriptor *sortByStartDate = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
	events = [events sortedArrayUsingDescriptors:@[sortByStartDate]];
	return events;
}

#define SECONDS_IN_DAY 24*60*60

- (NSArray *)eventsForDaysInRangeFromDate:(NSDate *)start toDate:(NSDate *)end {
	start = [self startOfLocalDay:start];
	end = [self startOfLocalDay:end];
	
	NSPredicate *predicate = [_eventStore predicateForEventsWithStartDate:start endDate:end calendars:_calendars];
	NSArray *events = [_eventStore eventsMatchingPredicate:predicate];
	if (!events) {
		return @[];
	}

	NSMutableArray *eventsForDays = [[NSMutableArray alloc] initWithCapacity:31];
	
	NSSortDescriptor *sortByStartDate = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES];
	events = [events sortedArrayUsingDescriptors:@[sortByStartDate]];
	
	NSDate *currentDay = start;
	NSInteger dayIndex = 0;
	NSInteger previousEndIndex = 0;
	do {
		NSInteger startIndex = -1, endIndex = -1;
		eventsForDays[dayIndex] = [NSNull null];
		
		for (NSInteger eventIndex = previousEndIndex; eventIndex < events.count; eventIndex++) {
			EKEvent *event = events[eventIndex];
			NSDate *eventStart = event.startDate;
			
			NSTimeInterval delta = [eventStart timeIntervalSinceDate:currentDay];
			if (startIndex == -1 && delta >= 0 && delta < SECONDS_IN_DAY) {
				startIndex = eventIndex;
			}
			if (delta >= SECONDS_IN_DAY) {
				if (startIndex != -1) {
					endIndex = eventIndex;
					previousEndIndex = endIndex;
					eventsForDays[dayIndex] = [events subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
				}
				break;
			}
		}
		dayIndex++;
		currentDay = [self addDays:1 toDay:currentDay];
	} while ([currentDay timeIntervalSinceDate:end] <= 0);
	
	return eventsForDays;
}

@end
