//
//  Task+Additions.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "RecurrenceRule+Additions.h"
#import "WSRootAppDelegate.h"
#import "MiscUtils.h"
#import "MiscUtils.h"
#import "Task.h"

@implementation RecurrenceRule (Additions)

+ (RecurrenceRule *)recurrenceRule
{
	RecurrenceRule *recurrenceRule = [[RecurrenceRule alloc] initWithEntity:[NSEntityDescription entityForName:@"RecurrenceRule" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	recurrenceRule.uuid = WSCreateUUID();
    
	return recurrenceRule;
}

- (BOOL)recursAtDate:(NSDate *)date {
	return [self recurrenceIndexForDate:date] >= 0;
}

- (NSInteger)recurrenceIndexForDate:(NSDate *)date {
	if (!self.task) {
		return -1;
	}
	
	NSArray *recurrenceIndexes = nil;
	NSArray *matchingTasks = WSRecurringTasksMatchingDayIgnoringExceptions(@[self.task], date, &recurrenceIndexes);

	if (matchingTasks.count == 0) {
		return -1;
	}

	return [recurrenceIndexes[0] integerValue];
}

#pragma mark - Completions

- (NSManagedObject *)completionForDate:(NSDate *)date {
	if (0 == self.completions.count) {
		return nil;
	}

	NSInteger recurrenceIndex = [self recurrenceIndexForDate:date];
	if (recurrenceIndex < 0) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"RecurrenceCompletion"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recurrenceRule.uuid = %@  AND recurrenceIndex = %@", self.uuid, @(recurrenceIndex)];
	[fetchRequest setPredicate:predicate];
	NSError *error = nil;
	NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	return [result firstObject];
}

- (BOOL)isCompletedAtDate:(NSDate *)date baseCompletion:(NSInteger)baseCompletion partial:(BOOL *)outPartial {
	NSManagedObject *completion = [self completionForDate:date];

	if (!completion) {
		if (outPartial) {
			*outPartial = (TASK_PARTIALLY_COMPLETED == baseCompletion);
		}
		return baseCompletion;
	}

	NSInteger completed = [[completion valueForKey:@"completed"] integerValue];
	if (outPartial) {
		*outPartial = (TASK_PARTIALLY_COMPLETED == completed);
	}
	return (TASK_COMPLETED == completed);

}

- (void)setCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial {
	NSManagedObject *completion = [self completionForDate:date];

	if (!completion) { // Have never created a completion yet for this recurrence
		completion = [self createCompletionWithIndex:[self recurrenceIndexForDate:date]];
		if (!completion) {
			return; // this date is not one of our recurring dates
		}
	}

	[self willChangeValueForKey:@"completions"];
	if (setPartial) {
		[completion setValue:@(TASK_PARTIALLY_COMPLETED) forKey:@"completed"];
	}
	else {
		[completion setValue:@(TASK_COMPLETED) forKey:@"completed"];
	}
	[self didChangeValueForKey:@"completions"];
}

- (void)toggleCompletedAtDate:(NSDate *)date baseCompletion:(NSInteger)baseCompletion partial:(BOOL)setPartial {
	NSManagedObject *completion = [self completionForDate:date];

	if (!completion) { // Have never created a completion yet for this recurrence
		completion = [self createCompletionWithIndex:[self recurrenceIndexForDate:date]];
		[completion setValue:[NSNumber numberWithInteger:baseCompletion] forKey:@"completed"];
		if (!completion) {
			return; // this date is not one of our recurring dates
		}
	}

	NSInteger completed = [[completion valueForKey:@"completed"] integerValue];

	[self willChangeValueForKey:@"completions"];
	if (TASK_PARTIALLY_COMPLETED == completed) {
		[completion setValue:@(TASK_COMPLETED) forKey:@"completed"];
	}
	else if (TASK_COMPLETED == completed) {
		if (setPartial) {
			[completion setValue:@(TASK_PARTIALLY_COMPLETED) forKey:@"completed"];
		}
		else {
			[completion setValue:@(TASK_NOT_COMPLETED) forKey:@"completed"];
		}
	}
	else if (TASK_NOT_COMPLETED == completed) {
		if (setPartial) {
			[completion setValue:@(TASK_PARTIALLY_COMPLETED) forKey:@"completed"];
		}
		else {
			[completion setValue:@(TASK_COMPLETED) forKey:@"completed"];
		}
	}
	[self didChangeValueForKey:@"completions"];
}

- (void)setUncompletedAtDate:(NSDate *)date {
	NSManagedObject *completion = [self completionForDate:date];

	if (!completion) { // Have never created a completion yet for this recurrence
		completion = [self createCompletionWithIndex:[self recurrenceIndexForDate:date]];
		if (!completion) {
			return; // this date is not one of our recurring dates
		}
	}

	[self willChangeValueForKey:@"completions"];
	[completion setValue:@(TASK_NOT_COMPLETED) forKey:@"completed"];
	[self didChangeValueForKey:@"completions"];
}

// edit popover from projects
	// ask if want to complete for all time or cancel
// spacebar
	// ask if want to complete for all time or cancel if from projects
// menu
// context menu
// TODO - when toggling from project view or edit popover w/o day, do something semi-inteligent (perhaps gray out box if day is nil (or date quantized to day))
// TODO - get completion toggle from spacebar working
// TODO - get completion toggle from context menu working


- (NSManagedObject *)createCompletionWithIndex:(NSInteger)recurrenceIndex {
	if (recurrenceIndex < 0) {
		return nil;
	}

	NSManagedObject *completion = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"RecurrenceCompletion" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	[completion setValue:WSCreateUUID() forKey:@"uuid"];
	[completion setValue:@(recurrenceIndex) forKey:@"recurrenceIndex"];
	[completion setValue:@(TASK_NOT_COMPLETED) forKey:@"completed"];

	[self addCompletionsObject:completion];
	return completion;
}

- (void)clearCompletions {
	for (NSManagedObject *obj in [self.completions copy]) {
		[self.managedObjectContext deleteObject:obj];
	}
}

#pragma mark - Exceptions

- (NSManagedObject *)exceptionForDate:(NSDate *)date {
	if (0 == self.exceptions.count) {
		return nil;
	}
	
	NSInteger recurrenceIndex = [self recurrenceIndexForDate:date];
	if (recurrenceIndex < 0) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"RecurrenceException"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recurrenceRule.uuid = %@  AND recurrenceIndex = %@", self.uuid, @(recurrenceIndex)];
	[fetchRequest setPredicate:predicate];
	NSError *error = nil;
	NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	return [result firstObject];
}

- (BOOL)hasExceptionForDate:(NSDate *)date {
	return [self exceptionForDate:date] != nil;
}

- (void)addExceptionForDate:(NSDate *)date {
	NSManagedObject *exception = [self exceptionForDate:date];

	if (!exception) {
		[self createExceptionWithIndex:[self recurrenceIndexForDate:date]];
	}
}

- (NSManagedObject *)createExceptionWithIndex:(NSInteger)recurrenceIndex {
	if (recurrenceIndex < 0) {
		return nil;
	}

	NSManagedObject *exception = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"RecurrenceException" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	[exception setValue:WSCreateUUID() forKey:@"uuid"];
	[exception setValue:@(recurrenceIndex) forKey:@"recurrenceIndex"];
	[self addExceptionsObject:exception];
	return exception;
}

- (void)clearExceptions {
	for (NSManagedObject *obj in [self.exceptions copy]) {
		[self.managedObjectContext deleteObject:obj];
	}
}

#pragma mark - Sorting

- (NSManagedObject *)sortIndexForDate:(NSDate *)date {
	if (0 == self.sortIndexes.count) {
		return nil;
	}
	
	NSInteger recurrenceIndex = [self recurrenceIndexForDate:date];
	if (recurrenceIndex < 0) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"RecurrenceSortIndex"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recurrenceRule.uuid = %@  AND recurrenceIndex = %@", self.uuid, @(recurrenceIndex)];
	[fetchRequest setPredicate:predicate];
	NSError *error = nil;
	NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	
	return [result firstObject];
}

- (NSInteger)sortIndexInDayForDate:(NSDate *)date {
	NSManagedObject *sortIndex = [self sortIndexForDate:date];
	
	if (sortIndex) {
		return [[sortIndex valueForKey:@"sortIndexInDay"] integerValue];
	}
	else {
		return [self.task.sortIndexInDay integerValue];
	}
}

- (void)setSortIndexInDay:(NSInteger)sortIndexInDay forDate:(NSDate *)date {
	NSManagedObject *sortIndex = [self sortIndexForDate:date];
	
	if (!sortIndex) {
		sortIndex = [self createSortIndexWithIndex:[self recurrenceIndexForDate:date]];
		if (!sortIndex) {
			return; // this date is not one of our recurring dates
		}
	}
	
	[self willChangeValueForKey:@"sortIndexes"];
	[sortIndex setValue:@(sortIndexInDay) forKey:@"sortIndexInDay"];
	[self didChangeValueForKey:@"sortIndexes"];
}

- (NSManagedObject *)createSortIndexWithIndex:(NSInteger)recurrenceIndex {
	if (recurrenceIndex < 0) {
		return nil;
	}
	
	NSManagedObject *sortIndex = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"RecurrenceSortIndex" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	[sortIndex setValue:WSCreateUUID() forKey:@"uuid"];
	[sortIndex setValue:@(recurrenceIndex) forKey:@"recurrenceIndex"];
	[self addSortIndexesObject:sortIndex];
	return sortIndex;
}

#pragma mark - misc

- (NSString *)simpleStringDescription {
	switch ([self.frequency integerValue]) {
		case DMRecurrenceFrequencyDaily:
			return @"repeats daily";
			break;
			
		case DMRecurrenceFrequencyWeekly:
			return @"repeats weekly";
			break;
			
		case DMRecurrenceFrequencyMonthly:
			return @"repeats monthly";
			break;
			
		case DMRecurrenceFrequencyYearly:
			return @"repeats yearly";
			break;
			
		case DMRecurrenceFrequencyBiweekly:
			return @"repeats every other week";
			break;
			
		default:
			return @"";
			break;
	}
	
}

@end
