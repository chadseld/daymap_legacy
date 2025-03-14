//
//  Task+Additions.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "Task+Additions.h"
#import "WSRootAppDelegate.h"
#import "MiscUtils.h"
#import "NSString+WS.h"
#import "DayMapManagedObjectContext.h"
#import "NSDate+WS.h"
#import "RecurrenceRule+Additions.h"
#import "AbstractTask+Additions.h"

#if TARGET_OS_IPHONE
#import "UIAlertView+blocks.h"
enum {
    NSAlertDefaultReturn		= 1,
    NSAlertAlternateReturn		= 0,
    NSAlertOtherReturn			= -1,
    NSAlertErrorReturn			= -2
};
#endif

#define WSAllOccurrences NSAlertDefaultReturn
#define WSJustThislOccurrence NSAlertAlternateReturn
#define WSCancel NSAlertOtherReturn

@implementation Task (Additions)

+ (Task *)task
{
	Task *task = [[Task alloc] initWithEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext] insertIntoManagedObjectContext:DMCurrentManagedObjectContext];
	task.uuid = WSCreateUUID();
	task.createdDate = [NSDate date];
    task.name = @"Untitled Task";
    
	// Currently we have a temporaryID. Since we are going to use the objectID for identification e.g. drag or save to prefs we need ampermanent one immediately.
//	NSError *error = nil;
//	if (![context obtainPermanentIDsForObjects:[NSArray arrayWithObject:task] error:&error]) {
//		// Operation failed, so we punt and do a slower save of all changes
//		[[(WSRootAppDelegate *)[NSApp delegate] managedObjectContext] save:NULL];
//	}
	
	return task;
}

#if !TARGET_OS_IPHONE
+ (void)placeTasks:(NSArray *)tasks onPasteboard:(NSPasteboard *)pboard fromDate:(NSDate *)fromDate
{
    NSArray *taskUUIDs = [tasks valueForKeyPath:@"uuid"];

	NSPasteboardItem *customTaskItem = [[NSPasteboardItem alloc] init];
	if (fromDate) {
		[customTaskItem setPropertyList:@{ @"taskUUIDs" : taskUUIDs,
										   @"fromDate" : fromDate} forType:DMTaskTableViewDragDataType];
	}
	else {
		[customTaskItem setPropertyList:@{ @"taskUUIDs" : taskUUIDs} forType:DMTaskTableViewDragDataType];
	}

	[customTaskItem setString:[self utf8FormattedStringForTasks:tasks] forType:NSPasteboardTypeString];
	[customTaskItem setString:[self utf8FormattedStringForTasks:tasks] forType:@"public.utf8-plain-text"];
	
	[pboard clearContents];
	[pboard writeObjects:@[customTaskItem]]; // TODO: write HTML, txt, RTF, opml, etc...
}

+ (NSArray *)tasksFromPasteboard:(NSPasteboard *)pboard fromDate:(NSDate **)outFromDate
{
	if (![pboard canReadItemWithDataConformingToTypes:@[DMTaskTableViewDragDataType]]) {
		return @[];
	}
	
    NSMutableArray *tasks = [NSMutableArray array];
	
	NSArray *customItems = [pboard readObjectsForClasses:@[[NSPasteboardItem class]] options:@{}];
	for (NSPasteboardItem *item in customItems) {
		if ([item availableTypeFromArray:@[DMTaskTableViewDragDataType]]) {
			NSDictionary *dict = [item propertyListForType:DMTaskTableViewDragDataType];
			NSArray *taskUUIDs = dict[@"taskUUIDs"];
			if (outFromDate) {
				*outFromDate = dict[@"fromDate"];
			}
			for (NSString *taskUUID in taskUUIDs) {
				Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
				if (task) [tasks addObject:task];
			}
			return tasks;
		}
	}
	return @[];
}

+ (NSString *)utf8FormattedStringForTasks:(NSArray *)rootTasks {
	if (rootTasks.count == 0) {
		return @"";
	}

	NSMutableString *result = [NSMutableString new];
	NSMutableSet *exportedSet = [NSMutableSet new];
	for (Task *task in rootTasks) {
		[result appendString:[self utf8FormattedStringForTask:task includingChildrenInSet:[NSSet setWithArray:rootTasks] exportedSet:exportedSet]];
	}
	return result;
}

+ (NSString *)utf8FormattedStringForTask:(Task *)task includingChildrenInSet:(NSSet *)includingSet exportedSet:(NSMutableSet *)exportedSet {
	
	NSMutableString *result = [NSMutableString new];
	
	// Don't export the same task twice
	if ([exportedSet containsObject:task]) {
		return @"";
	}
	[exportedSet addObject:task];

	// Calculate indentation
	NSString *indentation = @"";
	for (NSInteger i = task.breadcrumbs.count; i > 1; i--) {
		indentation = [indentation stringByAppendingString:@"\t"];
	}
	[result appendString:indentation];
	
	// Export task attributes
	if (TASK_COMPLETED == [task.completed integerValue]) {
		[result appendString:@"[X]"];
	}
	else if (TASK_PARTIALLY_COMPLETED == [task.completed integerValue]) {
		[result appendString:@"[-]"];
	}
	else {
		[result appendString:@"[ ]"];
	}
	[result appendString:@" "];
	[result appendString:task.name];
	[result appendString:@"\n"];
	
	// Export task children
	NSMutableArray *children = [[task sortedFilteredChildren] mutableCopy];
	NSMutableSet *intersection = [includingSet mutableCopy];
	[intersection intersectSet:[NSSet setWithArray:children]];
	if (intersection.count > 0) { // If the original selection contained some of these children, then only export those. Otherwise export all the children.
		for (NSInteger j = 0; j < children.count; j++) {
			if (![intersection containsObject:children[j]]) {
				[children removeObjectAtIndex:j];
				j--;
			}
		}
	}
	for (Task *child in children) {
		[result appendString:[self utf8FormattedStringForTask:child includingChildrenInSet:includingSet exportedSet:exportedSet]];
	}
	
	return result;
}

+ (NSString *)HTMLFormattedStringForTasks:(NSArray *)tasks {
	return @"";
}

#endif

#pragma mark - Recurring

// TODO - Apple does this even better with custom text for each use (e.g.)
// You're completing a repeating task. -- You're moving a repeating task. -- You're uncompleting a repeating task.
// You're deleting a repeating task.

- (void)askUserIfWantsToChangeCompleteAllOccurrencesIncludeThisOccurrence:(BOOL)includingThisOccurrence completion:(void (^)(NSInteger askResult))completion {
#if !TARGET_OS_IPHONE
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLocalizedString(@"You're changing a repeating task.", @"alert question")];

	if (includingThisOccurrence) {
		completion(WSJustThislOccurrence);
		return;
//		[alert setInformativeText:NSLocalizedString(@"Do you want to change only this occurrence, or change this and all occurrences?", @"alert question")];
//		[alert addButtonWithTitle:NSLocalizedString(@"Only this Occurrence", @"button")];
//		[alert addButtonWithTitle:NSLocalizedString(@"All Occurrences", @"button")];
//		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"button")];
//
//		NSInteger answer = [alert runModal];
//
//		if (answer == NSAlertFirstButtonReturn) {
//			completion(WSJustThislOccurrence);
//			return;
//		}
//		if (answer == NSAlertSecondButtonReturn) {
//			completion(WSAllOccurrences);
//			return;
//		}
	}
	else {
		[alert setInformativeText:NSLocalizedString(@"Do you want to change all occurrences?\n(Use the Calendar view to change a specific occurrence.)", @"alert question")];
		[alert addButtonWithTitle:NSLocalizedString(@"Change All Occurrences", @"button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"button")];

		NSInteger answer = [alert runModal];

		if (answer == NSAlertFirstButtonReturn) {
			completion(WSAllOccurrences);
			return;
		}
	}
	completion(WSCancel);

#else
	if (includingThisOccurrence) {
		completion(WSJustThislOccurrence);
		return;
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You're changing a repeating task.", @"alert question")
//														message:NSLocalizedString(@"Do you want to change only this occurrence, or change this and all occurrences?", @"alert question")
//													   delegate:nil
//											  cancelButtonTitle:NSLocalizedString(@"Cancel", @"button")
//											  otherButtonTitles:NSLocalizedString(@"Only this Occurrence", @"button"),
//							  NSLocalizedString(@"All Occurrences", @"button"), nil];
//		[alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
//			if (0 == buttonIndex) {
//				completion(WSCancel);
//				return;
//			}
//			if (1 == buttonIndex) {
//				completion(WSJustThislOccurrence);
//				return;
//			}
//			if (2 == buttonIndex) {
//				completion(WSAllOccurrences);
//				return;
//			}
//		}];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You're changing a repeating task.", @"alert question")
														message:NSLocalizedString(@"Do you want to change all occurrences?", @"alert question")
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Cancel", @"button")
											  otherButtonTitles:NSLocalizedString(@"Change All", @"button"), nil];
		[alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
			if (0 == buttonIndex) {
				completion(WSCancel);
				return;
			}
			if (1 == buttonIndex) {
				completion(WSAllOccurrences);
				return;
			}
		}];
	}
#endif
}

- (void)askUserIfWantsToChangeScheduleAllOccurrencesIncludeThisOccurrenceWithCompletion:(void (^)(NSInteger askResult))completion {
#if !TARGET_OS_IPHONE
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:NSLocalizedString(@"You're rescheduling a repeating task.", @"alert question")];
	[alert setInformativeText:NSLocalizedString(@"Do you want to reschedule all occurrences, or reschedule only this occurrence by creating a new task?", @"alert question")];
	[alert addButtonWithTitle:NSLocalizedString(@"Only this Occurrence", @"button")];
	[alert addButtonWithTitle:NSLocalizedString(@"All Occurrences", @"button")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"button")];

	NSInteger answer = [alert runModal];

	if (answer == NSAlertFirstButtonReturn) {
		completion(WSJustThislOccurrence);
		return;
	}
	if (answer == NSAlertSecondButtonReturn) {
		completion(WSAllOccurrences);
		return;
	}

	completion(WSCancel);

#else
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You're rescheduling a repeating task.", @"alert question")
													message:NSLocalizedString(@"Do you want to reschedule all occurrences, or reschedule only this occurrence by creating a new task?", @"alert question")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"Cancel", @"button")
										  otherButtonTitles:NSLocalizedString(@"Only this Occurrence", @"button"),
						  NSLocalizedString(@"All Occurrences", @"button"), nil];
	[alert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
		if (0 == buttonIndex) {
			completion(WSCancel);
			return;
		}
		if (1 == buttonIndex) {
			completion(WSJustThislOccurrence);
			return;
		}
		if (2 == buttonIndex) {
			completion(WSAllOccurrences);
			return;
		}
	}];
#endif
}

- (void)whichRecurrencesToChangeCompletedForDate:(NSDate *)date completion:(void (^)(NSInteger askResult))completion {
	if (self.repeat) {
		if ([self.repeat recursAtDate:date]) { // only ask if date does not fall on recurrence
			[self askUserIfWantsToChangeCompleteAllOccurrencesIncludeThisOccurrence:YES completion:completion];
			return;
		}
		else {
			[self askUserIfWantsToChangeCompleteAllOccurrencesIncludeThisOccurrence:NO completion:completion];
			return;
		}
	}
	completion(WSJustThislOccurrence);
}

- (void)whichRecurrencesToChangeScheduleForDate:(NSDate *)date completion:(void (^)(NSInteger askResult))completion {
	if (nil == date) {
		completion(WSAllOccurrences);
		return;
	}
	
	if (self.repeat) {
		if ([self.repeat recursAtDate:date]) { // only ask if date does not fall on recurrence
			[self askUserIfWantsToChangeScheduleAllOccurrencesIncludeThisOccurrenceWithCompletion:completion];
			return;
		}
	}
	completion(WSJustThislOccurrence);
}

- (NSDate *)recurringEndDate {

	if (nil == self.scheduledDate) {
		return [NSDate distantPast];
	}

	if (self.repeat.endAfterDate) {
		return self.repeat.endAfterDate;
	}

	if ([self.repeat.endAfterCount integerValue] > 0) {
		// We subtract 1 because the first repeat is the scheduled date itself
		if (DMRecurrenceFrequencyDaily == [self.repeat.frequency integerValue]) {
			return [self.scheduledDate dateByAddingDays:[self.repeat.endAfterCount integerValue] - 1];
		}
		else if (DMRecurrenceFrequencyWeekly == [self.repeat.frequency integerValue]) {
			return [self.scheduledDate dateByAddingWeeks:[self.repeat.endAfterCount integerValue] - 1];
		}
		else if (DMRecurrenceFrequencyBiweekly == [self.repeat.frequency integerValue]) {
			return [self.scheduledDate dateByAddingWeeks:([self.repeat.endAfterCount integerValue] - 1) * 2];
		}
		else if (DMRecurrenceFrequencyMonthly == [self.repeat.frequency integerValue]) {
			return [self.scheduledDate dateByAddingMonths:[self.repeat.endAfterCount integerValue] - 1];
		}
		else if (DMRecurrenceFrequencyYearly == [self.repeat.frequency integerValue]) {
			return [self.scheduledDate dateByAddingYears:[self.repeat.endAfterCount integerValue] - 1];
		}

	}

	return [NSDate distantFuture];
}

#pragma mark - Completed

- (BOOL)isCompletedAtDate:(NSDate *)date partial:(BOOL *)outPartial {
	if (self.repeat && [self.repeat recursAtDate:date]) {
		return [self.repeat isCompletedAtDate:date baseCompletion:[self.completed integerValue] partial:outPartial];
	}
	else {
		NSInteger completed = [self.completed integerValue];
		if (outPartial) {
			*outPartial = (TASK_PARTIALLY_COMPLETED == completed);
		}
		return (TASK_COMPLETED == completed);
	}
}

- (void)toggleCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial {
	[self whichRecurrencesToChangeCompletedForDate:date completion:^(NSInteger askResult) {
		if (WSCancel == askResult) {
			[self willChangeValueForKey:@"completed"];
			[self didChangeValueForKey:@"completed"];
			return; // Cancel
		}

		if (WSAllOccurrences == askResult) {
			[self.repeat clearCompletions];
		}

		if (self.repeat && WSJustThislOccurrence == askResult) {
			[self.repeat toggleCompletedAtDate:date baseCompletion:[self.completed integerValue] partial:setPartial];
		}
		else {
			NSInteger completed = [self.completed integerValue];
			if (TASK_PARTIALLY_COMPLETED == completed) {
				self.completed = [NSNumber numberWithInt:TASK_COMPLETED];
				self.completedDate = date ? : [NSDate today];
			}
			else if (TASK_COMPLETED == completed) {
				if (setPartial) {
					self.completed = [NSNumber numberWithInt:TASK_PARTIALLY_COMPLETED];
					self.completedDate = nil;
				}
				else {
					self.completed = [NSNumber numberWithInt:TASK_NOT_COMPLETED];
					self.completedDate = nil;
				}
			}
			else if (TASK_NOT_COMPLETED == completed) {
				if (setPartial) {
					self.completed = [NSNumber numberWithInt:TASK_PARTIALLY_COMPLETED];
					self.completedDate = nil;
				}
				else {
					self.completed = [NSNumber numberWithInt:TASK_COMPLETED];
					self.completedDate = date ? : [NSDate today];
				}
			}
		}
	}];
}

+ (void)toggleCompleted:(NSArray *)tasks atDate:(NSDate *)date {
	BOOL anyUncompleted = NO;
	BOOL anyCompleted = NO;
	for (Task *task in tasks) {
		if ([task isCompletedAtDate:date partial:nil]) {
			anyCompleted = YES;
		}
		else {
			anyUncompleted = YES;
		}
	}

	if (anyCompleted && !anyUncompleted) {
		for (Task *task in tasks) {
			[task setUncompletedAtDate:date];
		}
	}
	else {
		for (Task *task in tasks) {
			[task setCompletedAtDate:date partial:NO];
		}
	}
}

- (void)setCompletedAtDate:(NSDate *)date partial:(BOOL)setPartial {
	[self whichRecurrencesToChangeCompletedForDate:date completion:^(NSInteger askResult) {
		if (WSCancel == askResult) {
			[self willChangeValueForKey:@"completed"];
			[self didChangeValueForKey:@"completed"];
			return; // Cancel
		}

		if (WSAllOccurrences == askResult) {
			[self.repeat clearCompletions];
		}

		if (self.repeat && WSJustThislOccurrence == askResult) {
			[self.repeat setCompletedAtDate:date partial:setPartial];
		}
		else {
			if (setPartial) {
				self.completed = [NSNumber numberWithInt:TASK_PARTIALLY_COMPLETED];
			}
			else {
				self.completed = [NSNumber numberWithInt:TASK_COMPLETED];
			}
			self.completedDate = date ? : [NSDate today];
		}
	}];
}

- (void)setUncompletedAtDate:(NSDate *)date {
	[self whichRecurrencesToChangeCompletedForDate:date completion:^(NSInteger askResult) {
		if (WSCancel == askResult) {
			[self willChangeValueForKey:@"completed"];
			[self didChangeValueForKey:@"completed"];
			return; // Cancel
		}

		if (WSAllOccurrences == askResult) {
			[self.repeat clearCompletions];
		}

		self.completed = [NSNumber numberWithInt:TASK_NOT_COMPLETED];
		self.completedDate = nil;

		if (self.repeat && WSJustThislOccurrence == askResult) {
			[self.repeat setUncompletedAtDate:date];
		}
	}];
}

#pragma mark - Sorting

- (NSInteger)sortIndexInDayForDate:(NSDate *)date {
	if (self.repeat) {
		return [self.repeat sortIndexInDayForDate:date];
	}
	else {
		return [[self sortIndexInDay] integerValue];
	}
}

- (void)setSortIndexInDay:(NSNumber *)sortIndexInDay forDate:(NSDate *)date {
	if ([self.repeat recursAtDate:date]) {
		[self.repeat setSortIndexInDay:[sortIndexInDay integerValue] forDate:date];
	}
	else {
		[self setSortIndexInDay:sortIndexInDay];
	}
}

#pragma mark - Scheduled Date

- (void)setScheduledDate:(NSDate *)scheduledDate handlingRecurrenceAtDate:(NSDate *)recurrenceDate {
	[self whichRecurrencesToChangeScheduleForDate:recurrenceDate completion:^(NSInteger askResult) {
		if (WSCancel == askResult) {
			return; // Cancel
		}

		if (WSAllOccurrences == askResult) {
			[self.repeat clearExceptions];
		}

		if (WSJustThislOccurrence == askResult && self.repeat) {
			// Create a recurrence exception for this recurrence
			[self.repeat addExceptionForDate:recurrenceDate];

			// Create a new task -- mostly copying the current task except not repeating and schedule it at the scheduledDate
			Task *cloned = (Task *)WSCloneManagedObjectInContext(self, (DayMapManagedObjectContext *)self.managedObjectContext, NO);
			cloned.name = [cloned.name stringByAppendingString:@" (rescheduled)"];
			cloned.repeat = nil;
			cloned.scheduledDate = scheduledDate;
			[self.parent addChildrenObject:cloned];
		}
		else {
			self.scheduledDate = scheduledDate;
		}
	}];
}

#pragma mark -

- (NSString *)asHtml
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];

	NSMutableString *html = [[NSMutableString alloc] init];
	[html appendString:@"<div class=\"task\">"];
	if ([self.completed intValue] == TASK_COMPLETED) {
		[html appendString:@"<div class=\"completed\">"];		
	}
	[html appendString:@"<div class=\"name\">"]; [html appendString:[self.name ws_asLegalHtml] ? : @"-- Unnammed Task --"]; [html appendString:@"</div>"];
	if (self.completedDate && [self.completed intValue] == TASK_COMPLETED) { [html appendString:@"<div class=\"completedDate\"> - Completed on: "]; [html appendString:[dateFormatter stringFromDate: self.completedDate]]; [html appendString:@"</div>"]; }
	else if (self.scheduledDate) { [html appendString:@"<div class=\"scheduledDate\"> - Scheduled for: "]; [html appendString:[dateFormatter stringFromDate: self.scheduledDate]]; [html appendString:@"</div>"]; }

	if (self.attributedDetails) { [html appendString:@"<div class=\"details\">"]; [html appendString:[[self.attributedDetailsAttributedString string] ws_asLegalHtml]]; [html appendString:@"</div>"]; }
	[html appendString:@"<div class=\"children\">"];
	NSArray *filteredChildren = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(self.children, [(WSRootAppDelegate *)[NSApp delegate] completedDateFilter], nil, SORT_BY_SORTINDEX);
	for (Task *task in filteredChildren) {
		[html appendString:[task asHtml]];
	}
	[html appendString:@"</div>"]; // Children
	
	if ([self.completed intValue] == TASK_COMPLETED) {
		[html appendString:@"</div>"]; // Completed
	}
	
	[html appendString:@"</div>"]; // Project

	return html;
}

@end
