//
//  MiscUtils.cpp
//  DayMap
//
//  Created by Chad Seldomridge on 9/29/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "MiscUtils.h"
#import "Task+Additions.h"
#import "Project.h"
#import "RecurrenceRule+Additions.h"
#import "NSDate+WS.h"
#if !TARGET_OS_IPHONE
#import "VerifyStoreReceipt.h"
#endif
#import <CommonCrypto/CommonDigest.h>


#if !TARGET_OS_IPHONE
NSRect WSCenterRectInRect(NSSize inner, NSRect outer)
{
    return NSInsetRect(outer, (outer.size.width - inner.width)/2, (outer.size.height - inner.height)/2);
}

void WSDrawTestRect(NSRect rect) {
	[[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.7] set];
    NSFrameRect(rect);
    CGFloat dash[2] = {4, 3};
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(rect, 5.5, 5.5)];
    [path setLineDash:dash count:2 phase:0];
    [path stroke];
    
    [[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:0.7] set];
    NSRectFill(NSMakeRect(-6,-6,12,12));
}

BOOL WSIsOptionKeyPressed(void) {
	NSUInteger modifierFlags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
	BOOL result = (modifierFlags & NSAlternateKeyMask) != 0;
	return result;
}

// Version 1.7.1 was the last version in the App Store which was a paid app before we switched to the freemium model
// Users of 1.7.1 or earlier get the full unlocked app with no additional in-app purchase required
#define LAST_PAID_BUNDLE_VERSION 171

BOOL WSDayMapFullyPurchased(void) {
	static NSDictionary *receipt = nil;
	if (!receipt) {
		NSString * receiptPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
		receipt = dictionaryWithAppStoreReceipt(receiptPath);
	}
	
	NSString *originalVersion = [receipt valueForKey:kReceiptOriginalVersion];
	originalVersion = [originalVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
	NSInteger originalVersionNumber = [originalVersion integerValue];
	if (originalVersionNumber <= LAST_PAID_BUNDLE_VERSION) {
		return YES;
	}
	
	// TODO: parse in-app purchases and look for purchase
	
	return NO;
}
#endif

NSString* WSCreateUUID(void)
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (NSString *)CFBridgingRelease(string);
}

/*
 * tasks must be an array of Task objects
 * parent can be a Task or a Project object
 * index can be -1 which means insert at end
 */
NSArray *WSMoveTasksToParent(NSArray *tasks, NSManagedObject *parent, NSInteger index, BOOL copy)
{
	if (copy) {
		NSMutableArray *copiedTasks = [NSMutableArray new];
		for (Task *task in tasks) {
			[copiedTasks addObject:WSCloneManagedObjectInContext(task, DMCurrentManagedObjectContext, NO)];
		}
		tasks = copiedTasks;
	}
	
	
	NSMutableSet *toSet; // the actual set stored back into core data
	NSMutableOrderedSet *orderedTasks; // only used for set manipulation
	NSArray *sortedProjectTasks;

	[parent willChangeValueForKey:@"children"];		
	toSet = [parent mutableSetValueForKey:@"children"];

	sortedProjectTasks = [toSet sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	orderedTasks = [NSMutableOrderedSet orderedSetWithArray:sortedProjectTasks];
	if (-1 == index) {
		index = [toSet count];
	}
	//NSLog(@"toSet = %@", [toSet description]);

	for (Task *task in tasks) {
		if (![orderedTasks containsObject:task]) { // Move from one project to the other
			[toSet addObject:task];
		}
	}
	
	for (Task *task in tasks) {
		NSInteger taskIndex = [orderedTasks indexOfObject:task];
		if (NSNotFound == taskIndex) {
			continue;
		}
		[orderedTasks removeObjectAtIndex:taskIndex];
		if (taskIndex < index) index--;
	}
	
	for (Task *task in tasks) {
		[orderedTasks insertObject:task atIndex:index];
		index++;
	}
	
	// Update sort index
	NSInteger i = 0;
	for (Task *task in orderedTasks) { // update sortIndex
		task.sortIndex = [NSNumber numberWithInteger:i];
		i++;
	}
	
	//NSLog(@"done toSet = %@", [toSet description]);
	
	[parent didChangeValueForKey:@"children"];
	
	return [tasks valueForKey:@"uuid"];
}

NSArray* WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(NSSet *tasks, NSDate *completedBeforeDate, NSDate *completedOnDate, NSArray *sortDescriptors) {
	NSSet *filteredTasksSet = [tasks objectsPassingTest:^BOOL(id obj, BOOL *stop) {
		if ([[(NSManagedObject *)obj entity].name isEqualToString:@"Task"]) {
			Task *task = (Task *)obj;
			
			if (task.repeat && completedOnDate && NSOrderedAscending != [completedBeforeDate compare:completedOnDate]) {
				return ![task isCompletedAtDate:completedOnDate partial:nil];
			}
			else if ([task.completed intValue] != TASK_COMPLETED) {
				return YES;
			}
			else if (NSOrderedDescending == [task.completedDate compare:completedBeforeDate]) {
				return YES;
			}
			else if (nil == task.completedDate) {
				return YES;
			}
			else {
				return NO;
			}
		}
		else { // assume type is Project
			return (((AbstractTask *)obj).completedDate == nil || (NSOrderedDescending == [((AbstractTask *)obj).completedDate compare:completedBeforeDate]));
		}
	}];
	
	if (sortDescriptors) {
		return [filteredTasksSet sortedArrayUsingDescriptors:sortDescriptors];
	}
	else {
		return [filteredTasksSet allObjects];
	}
}

// Note: Caller must set parent, or dayMap, or task attribute. We only clone in one direction.
NSManagedObject* WSCloneManagedObjectInContext(NSManagedObject *source, DayMapManagedObjectContext *context, BOOL preserveUUID)
{
    NSString *entityName = [[source entity] name];
	
    //create new object in data store
    NSManagedObject *cloned = [NSEntityDescription
                               insertNewObjectForEntityForName:entityName
                               inManagedObjectContext:context];
	
    //loop through all attributes and assign then to the clone
    NSDictionary *attributes = [[NSEntityDescription
                                 entityForName:entityName
                                 inManagedObjectContext:context] attributesByName];
	
    for (NSString *attr in [attributes allKeys]) {
        [cloned setValue:[source valueForKey:attr] forKey:attr];
    }
	if (!preserveUUID) [cloned setValue:WSCreateUUID() forKey:@"uuid"];
	
    //Loop through all relationships, and clone them.
    NSDictionary *relationships = [[NSEntityDescription
                                    entityForName:entityName
                                    inManagedObjectContext:context] relationshipsByName];
    for (NSString *relName in [relationships allKeys]){
		if ([relName isEqualToString:@"parent"] || [relName isEqualToString:@"dayMap"] || [relName isEqualToString:@"task"] || [relName isEqualToString:@"recurrenceRule"]) continue; // Don't walk up the tree, only down.

        NSRelationshipDescription *rel = [relationships objectForKey:relName];
		
        if ([rel isToMany]) {
            //get a set of all objects in the relationship
			id sourceSet;
			id clonedSet;
			if ([rel isOrdered]) {
				sourceSet = [source mutableOrderedSetValueForKey:relName];
				clonedSet = [cloned mutableOrderedSetValueForKey:relName];
			}
			else {
				sourceSet = [source mutableSetValueForKey:relName];
				clonedSet = [cloned mutableSetValueForKey:relName];
			}
			for (NSManagedObject *relatedObject in [sourceSet copy]) {
				// Don't want to clone self over and over again in a loop
//				NSString *inverseRelationshipName = [[rel inverseRelationship] name];
//				if (inverseRelationshipName) {
//					[relatedObject setValue:nil forKey:inverseRelationshipName];
//				}
				// Clone it, and add clone to set
//                NSManagedObject *clonedRelatedObject = WSCloneManagedObjectInContext(relatedObject, context, preserveUUID);
//                [clonedSet addObject:clonedRelatedObject];
				NSManagedObject *localRelObj = [context objectWithUUID:[relatedObject valueForKey:@"uuid"]];
				NSManagedObject *clonedRelatedObject;
				DLog(@"cloning object: source (%@) must clone relationship object (%@ : %@) before assigning it", source, relName, relatedObject);
				if (!localRelObj) {
					clonedRelatedObject = WSCloneManagedObjectInContext(relatedObject, context, preserveUUID);
				}
				else {
					clonedRelatedObject = WSCloneManagedObjectInContext(relatedObject, context, NO);
				}
				[clonedSet addObject:clonedRelatedObject];

            }
		}
		else {
			NSManagedObject *relationshipObject = [source valueForKey:relName];
			if (relationshipObject) {
				NSManagedObject *localRelObj = [context objectWithUUID:[relationshipObject valueForKey:@"uuid"]];
				NSManagedObject *clonedRelatedObject;
				DLog(@"cloning object: source (%@) must clone relationship object (%@ : %@) before assigning it", source, relName, relationshipObject);
				if (!localRelObj) {
					clonedRelatedObject = WSCloneManagedObjectInContext(relationshipObject, context, preserveUUID);
				}
				else {
					clonedRelatedObject = WSCloneManagedObjectInContext(relationshipObject, context, NO);
				}
				[cloned setValue:clonedRelatedObject forKey:relName];
			}
        }
    }
	
    return cloned;
}

// Note: Caller must set parent, or dayMap, or task attribute. We only merge in one direction.
NSManagedObject* WSMergeObjectIntoObjectInContext(NSManagedObject *remoteObject, NSManagedObject *ourObject, DayMapManagedObjectContext *context)
{
	// if our obj is a tombstone, don't copy in the remote	
	BOOL ourObjectIsTombstone = [[[ourObject entity] name] isEqualToString:@"Tombstone"];
	if (ourObjectIsTombstone) {
		return ourObject; // Don't import the remote object
	}
	
	// Easy case if local does not exist
	if (nil == ourObject && nil != remoteObject) {
		return WSCloneManagedObjectInContext(remoteObject, context, YES);
	}
	
	if (nil != ourObject && nil == remoteObject) {
		return ourObject; // nothing to merge
	}
	
	if (nil == ourObject && nil == remoteObject) {
		return nil; // nothing to do at all
	}
	
	if (![[ourObject entity] isEqual:[remoteObject entity]]) {
		return WSCloneManagedObjectInContext(remoteObject, context, NO);
	}
	
	if (![[[ourObject entity] name] isEqualToString:@"DayMap"] &&
		![[[ourObject entity] name] isEqualToString:@"Tombstone"]) { // DayMap and Tombstone don't have modifiedDate
		//loop through all attributes and assign then to the clone
		NSDictionary *attributes = [[NSEntityDescription
									 entityForName:[[ourObject entity] name]
									 inManagedObjectContext:context] attributesByName];
		
		NSDate *ourDate = [ourObject valueForKey:@"modifiedDate"];
		NSDate *remoteDate = [remoteObject valueForKey:@"modifiedDate"];

		for (NSString *attr in [attributes allKeys]) {
			if ([attr isEqualToString:@"uuid"] || [attr isEqualToString:@"modifiedDate"]) continue; // Don't merge uuid or modifiedDate attributes
						
			if ([ourDate timeIntervalSinceReferenceDate] < [remoteDate timeIntervalSinceReferenceDate]) {
				[ourObject setValue:[remoteObject valueForKey:attr] forKey:attr];
			}
			else {
				// We already have the latest values
			}
		}
	}

	//Loop through all relationships, and clone them.
    NSDictionary *relationships = [[NSEntityDescription
                                    entityForName:[[remoteObject entity] name]
                                    inManagedObjectContext:context] relationshipsByName];
    for (NSString *relName in [relationships allKeys]){
		if ([relName isEqualToString:@"parent"] || [relName isEqualToString:@"dayMap"] || [relName isEqualToString:@"task"] || [relName isEqualToString:@"recurrenceRule"]) continue; // Don't walk up the tree, only down.

        NSRelationshipDescription *rel = [relationships objectForKey:relName];
		
        if ([rel isToMany]) {
            //get a set of all objects in the relationship
			id remoteSet;
			id ourSet;
			if ([rel isOrdered]) {
				remoteSet = [remoteObject mutableOrderedSetValueForKey:relName];
				ourSet = [ourObject mutableOrderedSetValueForKey:relName];
			}
			else {
				remoteSet = [remoteObject mutableSetValueForKey:relName];
				ourSet = [ourObject mutableSetValueForKey:relName];
			}
			for (NSManagedObject *relatedObject in [remoteSet copy]) {
				NSManagedObject *localRelObj = [context objectWithUUID:[relatedObject valueForKey:@"uuid"]];
				if (!localRelObj) {
					// Don't want to clone self over and over again in a loop
//					NSString *inverseRelationshipName = [[rel inverseRelationship] name];
//					if (inverseRelationshipName) {
//						[relatedObject setValue:nil forKey:inverseRelationshipName];
//					}
					//Clone it, and add clone to set
					NSManagedObject *clonedRelatedObject = WSCloneManagedObjectInContext(relatedObject, context, YES);
					[ourSet addObject:clonedRelatedObject];
				}
				else {
					WSMergeObjectIntoObjectInContext(relatedObject, localRelObj, context);
				}
            }
		}
		else {
//			if ([relName isEqualToString:@"parent"] || [relName isEqualToString:@"dayMap"] || [relName isEqualToString:@"task"] || [relName isEqualToString:@"recurrenceRule"]) continue; // Don't walk up the tree, only down.
			NSManagedObject *relationshipObject = [remoteObject valueForKey:relName];
			if (relationshipObject) {
				NSManagedObject *localRelObj = [context objectWithUUID:[relationshipObject valueForKey:@"uuid"]];
				if (!localRelObj) {
					DLog(@"merging object: must clone relationship before assigning it");
					localRelObj = WSCloneManagedObjectInContext(relationshipObject, context, YES);
					[ourObject setValue:localRelObj forKey:relName];
				}
				else {
					WSMergeObjectIntoObjectInContext(relationshipObject, localRelObj, context);
				}
			}
        }
    }
	return ourObject;
}

BOOL WSPrefUseICloudStorage(void) {
#if defined(TARGET_DAYMAP_LITE)
	return NO;
#endif

	BOOL prefShouldUseiCloud = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_ICLOUD_STORAGE];
	return prefShouldUseiCloud;
}

NSArray *WSRecurringTasksMatchingDayIgnoringExceptions(NSArray *tasks, NSDate *day, NSArray **outRecurrenceIndexes) {
	if (nil == day) {
		return nil;
	}
	
	static NSCalendar *calendar = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		calendar = [NSCalendar currentCalendar];
		calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	});
	
	NSMutableArray *tasksForDay = [NSMutableArray new];
	if (outRecurrenceIndexes) {
		*outRecurrenceIndexes = [NSMutableArray new];
	}

	day = [day dateQuantizedToDay];
	NSDate *startDate = day;
	NSDate *endDate = [startDate dateByAddingDays:1];

	if (tasks.count == 0) {
		return tasksForDay; // no matches
	}

	NSMutableArray *filteredCandidates = [tasks mutableCopy];

	// Filter to remove all with scheduled date later than day (not started yet)
	// TODO: -- this helps a bit, but it's not a big deal

	// Filter to remove all with end date before day
	for (NSInteger index = filteredCandidates.count - 1; index >= 0; index--) {
		Task *task = (Task *)[filteredCandidates objectAtIndex:index];
		if ([startDate timeIntervalSinceDate:[task recurringEndDate]] > 0) {
			[filteredCandidates removeObjectAtIndex:index];
		}
	}
	if (filteredCandidates.count == 0) return tasksForDay;

	// Cheat here for daily tasks. We can check the start date and schedule them w/o having to check further
	for (NSInteger index = filteredCandidates.count - 1; index >= 0; index--) {
		Task *task = (Task *)[filteredCandidates objectAtIndex:index];
		if (DMRecurrenceFrequencyDaily == [task.repeat.frequency integerValue] && [endDate timeIntervalSinceDate:task.scheduledDate] > 0) {
			[tasksForDay addObject:task];
			[filteredCandidates removeObject:task];
			NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:task.scheduledDate toDate:day options:0];
			if (outRecurrenceIndexes) [(NSMutableArray *)*outRecurrenceIndexes addObject:@(components.day)];
		}
	}
	if (filteredCandidates.count == 0) return tasksForDay;

	// Cheat here for weekly tasks. We can safely assume a week is always 7 days.
	for (NSInteger index = filteredCandidates.count - 1; index >= 0; index--) {
		Task *task = (Task *)[filteredCandidates objectAtIndex:index];
		if (DMRecurrenceFrequencyWeekly == [task.repeat.frequency integerValue]) {
			NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:task.scheduledDate toDate:day options:0];
			if ((components.day % 7) == 0 && components.day >= 0) {
				[tasksForDay addObject:task];
				[filteredCandidates removeObject:task];
				if (outRecurrenceIndexes) [(NSMutableArray *)*outRecurrenceIndexes addObject:@(components.day / 7)];
			}
		}
	}
	if (filteredCandidates.count == 0) return tasksForDay;

	// Cheat here for biweekly tasks. We can safely assume a week is always 14 days.
	for (NSInteger index = filteredCandidates.count - 1; index >= 0; index--) {
		Task *task = (Task *)[filteredCandidates objectAtIndex:index];
		if (DMRecurrenceFrequencyBiweekly == [task.repeat.frequency integerValue]) {
			NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:task.scheduledDate toDate:day options:0];
			if ((components.day % 14) == 0 && components.day >= 0) {
				[tasksForDay addObject:task];
				[filteredCandidates removeObject:task];
				if (outRecurrenceIndexes) [(NSMutableArray *)*outRecurrenceIndexes addObject:@(components.day / 14)];
			}
		}
	}
	if (filteredCandidates.count == 0) return tasksForDay;

	// now we have a small list of candidates
	// For day minus frequency duration until earliest scheduled date of candidates
	// For each frequency [month, year], since we have already accounted for day and week
	for (DMRecurrenceFrequency frequency = DMRecurrenceFrequencyMonthly; frequency <= DMRecurrenceFrequencyYearly; frequency++) {
		if (filteredCandidates.count == 0) {
			continue;
		}
		NSDate *proposedDate = [day dateQuantizedToDay];
		NSDate *earliestScheduledDateOfCandidates = [[filteredCandidates objectAtIndex:0] valueForKey:@"scheduledDate"];
		NSInteger recurrenceCount = 0;
		while ([proposedDate timeIntervalSinceDate:earliestScheduledDateOfCandidates] >= 0 && filteredCandidates.count > 0) {
			startDate = proposedDate;
			endDate = [startDate dateByAddingDays:1];

			// For all candidates
			for (NSInteger index = filteredCandidates.count - 1; index >= 0; index--) {
				Task *task = (Task *)[filteredCandidates objectAtIndex:index];
				// Check if matches proposed day
				if ([task.repeat.frequency integerValue] == frequency && [task.scheduledDate timeIntervalSinceDate:startDate] >= 0 && [task.scheduledDate timeIntervalSinceDate:endDate] < 0) {
					[tasksForDay addObject:task];
					[filteredCandidates removeObjectAtIndex:index];
					if (outRecurrenceIndexes) [(NSMutableArray *)*outRecurrenceIndexes addObject:@(recurrenceCount)];
				}
			}

			// Decrement by frequency duration
			if (DMRecurrenceFrequencyMonthly == frequency) {
				proposedDate = [proposedDate dateByAddingMonths:-1];
			}
			else if (DMRecurrenceFrequencyYearly == frequency) {
				proposedDate = [proposedDate dateByAddingYears:-1];
			}
			recurrenceCount++;
		}
	}

	return tasksForDay;
}

NSString *WSSHAFromFileAtURL(NSURL *url) {
	unsigned char outputData[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256_CTX ctx;
	CC_SHA256_Init(&ctx);

	const NSUInteger kBufferSize = 8192;
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:url error:NULL];
	if (!handle) return nil;

	while (YES) {
		@autoreleasepool {
			NSData *chunk = [handle readDataOfLength:kBufferSize];
			CC_SHA256_Update(&ctx, [chunk bytes], (CC_LONG)[chunk length]);
			if (chunk.length < kBufferSize) {
				break;
			}
		}
	}
	[handle closeFile];

	CC_SHA256_Final(outputData, &ctx);

	NSMutableString *hash = [[NSMutableString alloc] init];

    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", outputData[i]];
    }

    return hash;
}
