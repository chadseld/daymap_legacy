//
//  Header.h
//  DayMap
//
//  Created by Chad Seldomridge on 9/29/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#if !TARGET_OS_IPHONE
	#include <Cocoa/Cocoa.h>
#else
	#include <UIKit/UIKit.h>
#endif

#ifndef DayMap_Header_h
#define DayMap_Header_h

#import "DayMapManagedObjectContext.h"

#define SORT_BY_SORTINDEX [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]]
#define SORT_BY_SORTINDEX_DAY [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortIndexInDay" ascending:YES]]

#ifdef __cplusplus
extern "C" {
#endif

#if !TARGET_OS_IPHONE
    NSRect WSCenterRectInRect(NSSize inner, NSRect outer);
	void WSDrawTestRect(NSRect rect);
#endif
	NSString* WSCreateUUID(void);
	NSArray *WSMoveTasksToParent(NSArray *tasks, NSManagedObject *parent, NSInteger index, BOOL copy);
	NSArray* WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(NSSet *tasks, NSDate *completedBeforeDate, NSDate *completedOnDate, NSArray *sortDescriptors);
	NSManagedObject* WSCloneManagedObjectInContext(NSManagedObject *source, DayMapManagedObjectContext *context, BOOL preserveUUID);
	NSManagedObject* WSMergeObjectIntoObjectInContext(NSManagedObject *remoteObject, NSManagedObject *ourObject, DayMapManagedObjectContext *context);
	BOOL WSIsOptionKeyPressed(void);
	BOOL WSDayMapFullyPurchased(void);
	
	BOOL WSPrefUseICloudStorage(void);

	NSArray *WSRecurringTasksMatchingDayIgnoringExceptions(NSArray *tasks, NSDate *day, NSArray **outRecurrenceIndexes);

	NSString *WSSHAFromFileAtURL(NSURL *url);
#ifdef __cplusplus
}
#endif

#endif
