//
//  WSRootAppDelegate.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/24/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import "WSRootAppDelegate.h"
#import "DayMap.h"
#import "Project.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "NSDate+WS.h"
#import "MiscUtils.h"
#import "RecurrenceRule+Additions.h"
#import <pwd.h>

DayMapManagedObjectContext *DMCurrentManagedObjectContext = nil;

@interface WSRootAppDelegate () {
	NSPersistentStore *_persistentStore;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectModel *_managedObjectModel;
	NSUndoManager *_undoManager;
	NSURL *_presentedItemURL;
	NSOperationQueue *_presentedItemOperationQueue;
}

@end


@implementation WSRootAppDelegate

@synthesize selectedTasks = _selectedTasks;
@synthesize selectedProject = _selectedProject;

#pragma mark - Core Data

- (NSManagedObjectModel *)defaultManagedObjectModel
{
	@synchronized(self) {
		if (_managedObjectModel) {
			return _managedObjectModel;
		}
		
        DLog(@"Creating managedObjectModel");
        
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DayMap" withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		return _managedObjectModel;
	}
}

- (void)setupCoreDataStack
{
    DMCurrentManagedObjectContext = [[DayMapManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	DMCurrentManagedObjectContext.undoManager = [self undoManager];
    
    
    NSManagedObjectModel *mom = [self defaultManagedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return;
    }
	
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    if (!_persistentStoreCoordinator) {
#if !TARGET_OS_IPHONE
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
#else
		NSLog(@"Error creating persistent store coordinator");
#endif
        return;
    }
    [DMCurrentManagedObjectContext performBlockAndWait:^{
        [DMCurrentManagedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
        [DMCurrentManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextWillSaveNotification:) name:NSManagedObjectContextWillSaveNotification object:nil];
}

- (void)tearDownCoreDataStack
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:nil];

    _managedObjectModel = nil;
    DMCurrentManagedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}

- (void)loadPersistentStoreStartupWorkflow
{
	BOOL prefShouldUseiCloud = WSPrefUseICloudStorage();
	BOOL userLoggedInToiCloud = [self isUserLoggedIntoICloud];

	[self disableFilePresenter];
	[self unloadPersistentStore];

	// Check if was syncing to iCloud and now logged out
    if (prefShouldUseiCloud && !userLoggedInToiCloud) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:PREF_USE_ICLOUD_STORAGE];
#if !TARGET_OS_IPHONE
        NSRunAlertPanel(NSLocalizedString(@"iCloud Sync Disabled", @"error dialog"),
						NSLocalizedString(@"This Mac has been logged out of iCloud. iCloud synced DayMap data will not be available unless iCloud is enabled in System Preferences and DayMap Preferences. ", @"error dialog"),
						NSLocalizedString(@"OK", @"error dialog"), nil, nil);
#else
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"iCloud Sync Disabled", @"error dialog") message:NSLocalizedString(@"This device has been logged out of iCloud. iCloud synced DayMap data will not be available unless iCloud is enabled in Settings and DayMap Preferences. ", @"error dialog") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"error dialog") otherButtonTitles:nil] show];
#endif
    }

	if (prefShouldUseiCloud && userLoggedInToiCloud) {
		[self loadUbiquitousPersistentStore];
		[self mergeConflicts];
	}
	else {
		
		[self loadLocalPersistentStore];
	}

	[self performDBCleanup];

	[self enableFilePresenterForURL:[self presentedItemURL]];
}

- (void)checkToImportDayMapLiteData {
#if !TARGET_OS_IPHONE
#ifndef TARGET_DAYMAP_LITE
	// Am running full version of dayMap. Check if need to import lite data file
	NSString *lastImportedLiteDataSHA = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_LAST_IMPORTED_DAYMAP_LITE_SHA];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[[self liteLocalStoreURL] path]] &&
		![lastImportedLiteDataSHA isEqualToString:WSSHAFromFileAtURL([self liteLocalStoreURL])]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Import data from DayMap Lite?", @"import alert")
										 defaultButton:NSLocalizedString(@"Import", @"import alert")
									   alternateButton:NSLocalizedString(@"Don't Import", @"import alert")
										   otherButton:nil
							 informativeTextWithFormat:NSLocalizedString(@"DayMap has located data from DayMap Lite. Would you like to import this data?", @"import alert")];
		NSInteger alertResult = [alert runModal];
		if (NSAlertDefaultReturn == alertResult) {
			BOOL success = [self mergeDayMapStoreAtURL:[self liteLocalStoreURL]];
			if (!success) {
				NSLog(@"Failed to import DayMap Lite data");
			}
		}
		[[NSUserDefaults standardUserDefaults] setObject:WSSHAFromFileAtURL([self liteLocalStoreURL]) forKey:PREF_LAST_IMPORTED_DAYMAP_LITE_SHA];
	}
#endif
#endif
}

- (void)managedObjectContextWillSaveNotification:(NSNotification *)notification {
	DLog(@"managedObjectContextWillSaveNotification");
	
	if ([notification object] != DMCurrentManagedObjectContext) {
		return;
	}
	
	NSSet *deleted = DMCurrentManagedObjectContext.deletedObjects;
	
	for (NSManagedObject *obj in deleted) {
		if ([[[obj entity] name] isEqualToString:@"Tombstone"]) continue;

		NSManagedObject *tombstone = [NSEntityDescription
						  insertNewObjectForEntityForName:@"Tombstone"
						  inManagedObjectContext:DMCurrentManagedObjectContext];
		DLog(@"Creating Tombstone for %@", obj.entity.name);
		[tombstone setValue:[obj valueForKey:@"uuid"] forKey:@"uuid"];
		[tombstone setValue:[NSDate date] forKey:@"createdDate"];
	}
	
	NSSet *updated = DMCurrentManagedObjectContext.updatedObjects;
	NSSet *inserted = DMCurrentManagedObjectContext.insertedObjects;
	
	NSDate *currentDate = [NSDate date];
	for (NSManagedObject *obj in [updated setByAddingObjectsFromSet:inserted]) {
		if ([[[obj entity] name] isEqualToString:@"DayMap"] ||
			[[[obj entity] name] isEqualToString:@"Tombstone"]) continue; // DayMap and Tombstone don't have modifiedDate
		[obj setValue:currentDate forKey:@"modifiedDate"];
	}
}

#pragma mark - Persistent Store Handling

- (void)migrateDataModelFromv1tov2
{
	// Migrate from data model DayMap -> DayMap 2. From NSOrderedSet set to NSSet set with sortIndex
	NSSet *projects = DMCurrentManagedObjectContext.dayMap.projects;
	if ([((Project *)[projects anyObject]).sortIndex integerValue] == -1) // first launch after migration
	{
		NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
		NSInteger i = 0;
		for (Project *project in sortedProjects) {
			NSInteger j = 0;
			for (Task *task in project.children) {
				task.sortIndex = [NSNumber numberWithInteger:j];
				j++;
				
				// completedDate was never set in the old version
				if ([task.completed intValue] == TASK_COMPLETED && nil == task.completedDate) {
					if (NSOrderedAscending == [task.scheduledDate compare:[NSDate date]]) task.completedDate = task.scheduledDate;
					else task.completedDate = [[NSDate today] dateByAddingDays:-1]; // a total hack, but we forgot to set completed date or even created date in previos 1.0.2
				}
			}
			
			project.sortIndex = [NSNumber numberWithInteger:i];
			i++;
		}
	}
	
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @2;
}

- (void)migrateDataModelFromv2tov3
{
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @3;
}

- (void)migrateDataModelFromv3tov4
{
	//go through all objects. If they don't have a UUID, assign one.
	
	// Task
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSError *error;
	NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// Project
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:DMCurrentManagedObjectContext]];
	result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// DayMap
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"DayMap" inManagedObjectContext:DMCurrentManagedObjectContext]];
	result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// ProjectDisplayAttributes
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"ProjectDisplayAttributes" inManagedObjectContext:DMCurrentManagedObjectContext]];
	result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// Reminder
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Reminder" inManagedObjectContext:DMCurrentManagedObjectContext]];
	result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// RepeatDefinition
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"RepeatDefinition" inManagedObjectContext:DMCurrentManagedObjectContext]];
	result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in result) {
		[obj setValue:WSCreateUUID() forKey:@"uuid"];
	}
	
	// set daymap.dataModelVersion to 4
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @4;
}

- (void)migrateDataModelFromv4tov5
{
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @5;
}

- (void)migrateDataModelFromv5tov6
{
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @6;
}

- (void)migrateDataModelFromv6tov7
{
	// Add createdDate to Tombstones
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tombstone" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSError *error;
	NSArray *tombstones = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in tombstones) {
		[obj setValue:[NSDate date] forKey:@"createdDate"];
	}

	// Remove orphans
	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"RecurrenceRule" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSArray *recurrenceRules = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (NSManagedObject *obj in [recurrenceRules copy]) {
		if ([obj valueForKey:@"task"] == nil) {
			[DMCurrentManagedObjectContext deleteObject:obj];
		}
	}

	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"scheduledDate != nil AND repeat != nil AND completed = %d AND completedDate != nil", TASK_COMPLETED];
	NSArray *completedRecurringTasks = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (Task *task in completedRecurringTasks) {
		NSDate *completedUpTil = [task.completedDate dateQuantizedToDay];
		if (!completedUpTil) {
			completedUpTil = [NSDate today];
		}

		if ([completedUpTil isEqualToDate:[[NSDate distantFuture] dateQuantizedToDay]] ||
			[completedUpTil timeIntervalSinceDate:[[task recurringEndDate] dateQuantizedToDay]] >= 0) {
			task.completed = [NSNumber numberWithInt:TASK_COMPLETED];
			task.completedDate = completedUpTil;
		}
		else {
			NSDate *date = [task.scheduledDate dateQuantizedToDay];
			NSInteger errorIfGreaterThan = 0;
			while (date && [date timeIntervalSinceDate:completedUpTil] <= 0) {
				[task.repeat setCompletedAtDate:date partial:NO];

				if (DMRecurrenceFrequencyDaily == [task.repeat.frequency integerValue]) {
					date = [date dateByAddingDays:1];
				}
				else if (DMRecurrenceFrequencyWeekly == [task.repeat.frequency integerValue]) {
					date = [date dateByAddingWeeks:1];
				}
				else if (DMRecurrenceFrequencyBiweekly == [task.repeat.frequency integerValue]) {
					date = [date dateByAddingWeeks:2];
				}
				else if (DMRecurrenceFrequencyMonthly == [task.repeat.frequency integerValue]) {
					date = [date dateByAddingMonths:1];
				}
				else if (DMRecurrenceFrequencyYearly == [task.repeat.frequency integerValue]) {
					date = [date dateByAddingYears:1];
				}
				else {
					break;
				}
				errorIfGreaterThan ++;
				if (errorIfGreaterThan > 2000) {
					break;
				}
			}
		}
	}

	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @7;
}

- (void)migrateDataModelFromv7tov8 {

	////////////////
	// The grand migration to GMT Dates
	//
	// In the past, whenever we did a date quantizedToFoo, we ended up with a date in the local time zone.
	// We need to undo this mistake and do all future calendrical calculations in GMT.
	////////////////
	
	NSDate * (^convertLocalDateToGMT)(NSDate *) = ^NSDate *(NSDate *localDate) {
		NSCalendar *localCal = [NSCalendar currentCalendar];
		localCal.timeZone = [NSTimeZone localTimeZone];
		
		NSDateComponents *components = [localCal components:
										NSCalendarUnitYear |
										NSCalendarUnitMonth |
										NSCalendarUnitDay |
										NSCalendarUnitHour |
										NSCalendarUnitMinute
											  fromDate:localDate];
		
		NSCalendar *gmtCal = [NSCalendar currentCalendar];
		gmtCal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

		NSDate *day = [gmtCal dateFromComponents:components];
		return day;
	};

	void (^updateLocalDateToGMTForKey)(NSManagedObject *, NSString *) = ^void(NSManagedObject *obj, NSString *key) {
		if ([obj valueForKey:key]) {
			[obj setValue:convertLocalDateToGMT([obj valueForKey:key]) forKey:key];
		}
	};

	NSArray *entityNames = [DMCurrentManagedObjectContext entityNames];
	
	for (NSString *name in entityNames) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:DMCurrentManagedObjectContext]];
		NSError *error;
		NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
		for (NSManagedObject *obj in result) {
			// Modified Date
			if (![[[obj entity] name] isEqualToString:@"DayMap"] &&
				![[[obj entity] name] isEqualToString:@"Tombstone"]) { // DayMap and Tombstone don't have modifiedDate
				updateLocalDateToGMTForKey(obj, @"modifiedDate");
			}
			
			if ([[[obj entity] name] isEqualToString:@"AbstractTask"]) {
				updateLocalDateToGMTForKey(obj, @"completedDate");
				updateLocalDateToGMTForKey(obj, @"createdDate");
			}

			if ([[[obj entity] name] isEqualToString:@"Task"]) {
				updateLocalDateToGMTForKey(obj, @"scheduledDate");
			}
			
			if ([[[obj entity] name] isEqualToString:@"RecurrenceRule"]) {
				updateLocalDateToGMTForKey(obj, @"endAfterDate");
			}
		}
	}

	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @8;
}

- (void)migrateDataModelFromv8tov9 {
	DMCurrentManagedObjectContext.dayMap.dataModelVersion = @9;
}

- (void)loadUbiquitousPersistentStore
{
    DLog(@"loadUbiquitousPersistentStore");
	
    _presentedItemURL = [self ubiquitousStoreURL];
    [self loadPersistentStoreAtPresentedItemURL];
}

- (void)loadLocalPersistentStore
{
    DLog(@"loadLocalPersistentStore");
	
    _presentedItemURL = [self localStoreURL];
	[self loadPersistentStoreAtPresentedItemURL];
}

- (void)loadPersistentStoreAtPresentedItemURL
{
    DLog(@"Loading persistent store at URL: %@", _presentedItemURL);
    
	NSError *coordinatorError = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
	[coordinator coordinateReadingItemAtURL:_presentedItemURL options:0 error:&coordinatorError byAccessor:^(NSURL *newURL) {
		
		NSError *metadataError = nil;
		NSDictionary *storeMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSBinaryStoreType URL:newURL error:&metadataError];
		NSLog(@"Loading store with metadata %@", storeMetadata);
		
		NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @(YES),
								  NSInferMappingModelAutomaticallyOption : @(YES)};
								
		[_persistentStoreCoordinator performBlockAndWait:^{
			NSError *psError = nil;
			_persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:newURL options:options error:&psError];
			if (!_persistentStore) {
				_persistentStoreCoordinator = nil;
				NSLog(@"%@", psError);
#if !TARGET_OS_IPHONE
				NSRunAlertPanel(
								NSLocalizedString(@"Error loading DayMap data", @"error dialog"),
								NSLocalizedString(@"The DayMap data file was likely created with a newer version of DayMap. Please check the App Store for updates.", @"error dialog"),
								NSLocalizedString(@"OK", @"error dialog"), nil, nil);
				[NSApp terminate:self];
#else
				[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error loading DayMap data", @"error dialog") message:NSLocalizedString(@"The DayMap data file was likely created with a newer version of DayMap. Please check the App Store for updates.", @"error dialog") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"error dialog") otherButtonTitles:nil] show];
#endif
			}
		}];
        [DMCurrentManagedObjectContext updateHash];
	}];
	if (coordinatorError) {
		DLog(@"Error coordinating read of URL '%@': %@", _presentedItemURL, coordinatorError);
#if !TARGET_OS_IPHONE
		NSRunAlertPanel(
						NSLocalizedString(@"Error loading DayMap data", @"error dialog"),
						@"The system is not permitting access to the DayMap file. This could be related to iCloud syncing. If this problem persists, restart DayMap or reboot your Mac. %@",
						NSLocalizedString(@"OK", @"error dialog"), nil, nil, [coordinatorError localizedDescription]);
#else
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error loading DayMap data", @"error dialog") message:[coordinatorError localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"error dialog") otherButtonTitles:nil] show];
#endif
	}

	//***********
	// NOTE: also change in [DayMapManagedObjectContext dayMap] !!!
	//***********
	NSLog(@"Migrating from DayMap data version %d", [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]);
	if (1 >= [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv1tov2];
	}
	if (2 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv2tov3];
	}
	if (3 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv3tov4];
	}
	if (4 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv4tov5];
	}
	if (5 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv5tov6];
	}
	if (6 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv6tov7];
	}
	if (7 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv7tov8];
	}
	if (8 == [DMCurrentManagedObjectContext.dayMap.dataModelVersion intValue]) {
		[self migrateDataModelFromv8tov9];
	}
	NSLog(@"Finished migration.");
}

- (void)unloadPersistentStore
{
    DLog(@"unloadPersistentStore");
    
    [_persistentStoreCoordinator performBlockAndWait:^{
		for (NSPersistentStore *store in [[_persistentStoreCoordinator persistentStores] copy]) {
			NSError *psError = nil;
			if (![_persistentStoreCoordinator removePersistentStore:store error:&psError]) {
				DLog(@"Error removing persistent store = %@", psError);
			}
		}
		_persistentStore = nil;
	}];
}

- (void)seedUbiquitousPersistentStore
{
    DLog(@"seedUbiquitousPersistentStore");
    
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *ubiquitousStoreURL = [self ubiquitousStoreURL];
	
	// Delete old icloud data
	__block BOOL exists = NO;
	NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
	[coordinator coordinateReadingItemAtURL:ubiquitousStoreURL options:0 error:&error byAccessor:^(NSURL *newURL) {
		if([fileManager fileExistsAtPath:[newURL path]]) {
			exists = YES;
		}
	}];
	if (error) {
		NSLog(@"Error coordinating read at url '%@': %@", ubiquitousStoreURL, error);
	}
	if (exists) {
		[coordinator coordinateWritingItemAtURL:ubiquitousStoreURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *newURL) {
			NSError *fileSystemError;
			if(![fileManager removeItemAtPath:[newURL path] error:&fileSystemError]) {
				NSLog(@"Error deleting directory %@", fileSystemError);
			}
		}];
	}
	
	// Copy the file
	[coordinator coordinateReadingItemAtURL:[self localStoreURL] options:0 writingItemAtURL:ubiquitousStoreURL options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
		NSError *copyError = nil;
		if (![fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:&copyError]) {
			NSLog(@"Error copying item at URL %@ to URL %@: %@", newReadingURL, newWritingURL, error);
		}
	}];
	if (error) {
		NSLog(@"Error coordinating read at url '%@', write at url '%@': %@", [self localStoreURL], ubiquitousStoreURL, error);
	}
}

- (void)performDBCleanup {
#ifdef DEBUG
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tombstone" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSError *error;
	NSArray *tombstones = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];

	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSArray *projects = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];

	fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSArray *tasks = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];

	DLog(@"%ld Projects, %ld Tasks, %ld Tombstones", (unsigned long)projects.count, (unsigned long)tasks.count, (unsigned long)tombstones.count);
#endif

	// Remove old tombstones
	if (YES) {
		// Technically we should leave tombstones alive forever. But I don't like how messy that is.
		// I'm deleting old tombstones because if you have a sync conflict 90+ days old, you have bigger problems.
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tombstone" inManagedObjectContext:DMCurrentManagedObjectContext]];
		NSDate *oldDate = [[NSDate date] dateByAddingDays:-90];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(createdDate < %@)", oldDate];
		NSError *error;
		NSArray *oldTombstones = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (oldTombstones.count > 0) DLog(@"Deleting %ld old Tombstones", (unsigned long)oldTombstones.count);
		for (NSManagedObject *obj in oldTombstones) {
			[DMCurrentManagedObjectContext deleteObject:obj];
		}
	}

	// Remove orphans
//	if (NO) {
//		// Task
//		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
//		NSError *error;
//		NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
//		for (NSManagedObject *obj in [result copy]) {
//			if ([obj valueForKey:@"parent"] == nil) {
//				[DMCurrentManagedObjectContext deleteObject:obj];
//			}
//		}
//		
//		// Project
//		fetchRequest = [[NSFetchRequest alloc] init];
//		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:DMCurrentManagedObjectContext]];
//		result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
//		for (NSManagedObject *obj in [result copy]) {
//			if ([obj valueForKey:@"dayMap"] == nil && ![DMCurrentManagedObjectContext.dayMap.inbox.uuid isEqualToString:[obj valueForKey:@"uuid"]]) {
//				[DMCurrentManagedObjectContext deleteObject:obj];
//			}
//		}
//	}

	// Fix missing completed date
//	if (NO) {
//		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
//		NSError *error;
//		NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
//		for (NSManagedObject *obj in [result copy]) {
//			Task *task = (Task *)obj;
//			if ([task.completed integerValue] == TASK_COMPLETED && nil == task.completedDate) {
//				task.completedDate = [NSDate today];
//			}
//		}
//
//	}
}

- (void)saveContext
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Check for conflicts
	__block BOOL hasConflicts = NO;
	NSError *error = nil;
	NSURL *dataFileURL = [self presentedItemURL];
	[[[NSFileCoordinator alloc] initWithFilePresenter:self] coordinateReadingItemAtURL:dataFileURL options:0 error:&error byAccessor:^(NSURL *newURL) {
		NSArray *conflicts = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:newURL];
		if (conflicts.count > 0) {
			hasConflicts = YES;
		}
	}];
	
	if (hasConflicts) {
		[DMCurrentManagedObjectContext forceBackup]; // Lets save a backup here because iCloud is very buggy
		DLog(@"Merging conflicts...");
		[self mergeConflicts];
	}

	[DMCurrentManagedObjectContext performBlockAndWait:^{
		DLog(@"Saving before exit");
        if (![DMCurrentManagedObjectContext hasChanges]) {
            return;
        }
		
        NSError *error = nil;
        if (![DMCurrentManagedObjectContext save:&error]) {
			NSLog(@"Failed to save managed object context: %@", error);
        }
    }];
}

#pragma mark - iCloud

- (BOOL)isUserLoggedIntoICloud {
	return ([[NSFileManager defaultManager] ubiquityIdentityToken] != nil);
}

- (IBAction)toggleiCloud:(id)sender
{
#if defined(TARGET_DAYMAP_LITE)
	return;
#endif

	// Save current context to disk
	NSError *error = nil;
	[DMCurrentManagedObjectContext save:&error];
	[DMCurrentManagedObjectContext forceBackup];
	
	// Toggle pref
	BOOL prefShouldUseiCloud = WSPrefUseICloudStorage(); // read current value
	prefShouldUseiCloud = !prefShouldUseiCloud; // toggle pref value
		
	if (prefShouldUseiCloud) { // Turn on iCloud
		
		// Check if user logged in to iCloud account
		if (![self isUserLoggedIntoICloud]) {
#if !TARGET_OS_IPHONE
			NSRunAlertPanel(NSLocalizedString(@"Not logged in to iCloud", @"error dialog"),
							NSLocalizedString(@"This Mac has not been logged in to iCloud. Please log in to your iCloud account.\n\n(System Preferences > iCloud)\n\nAlso make sure the Documents & Data option is enabled.", @"error dialog"),
							NSLocalizedString(@"OK", @"error dialog"), nil, nil);
#else
			[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not logged in to iCloud", @"error dialog") message:NSLocalizedString(@"This device has not been logged in to iCloud. Please log in to your iCloud account via Settings > iCloud.", @"error dialog") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"error dialog") otherButtonTitles:nil] show];
#endif
			return;
		}

		// Determine if should seed iCloud here or just join it
#if !TARGET_OS_IPHONE
		const int kOverwriteAndSeed = NSAlertOtherReturn,
			  kMerge = NSAlertDefaultReturn,
			  kCancel = NSAlertAlternateReturn;
#else
		const int kOverwriteAndSeed = -1,
				kMerge = 1,
				kCancel = 0;
#endif
		__block NSInteger joinAction = kCancel;
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
		[coordinator coordinateReadingItemAtURL:[self ubiquitousStoreURL] options:0 error:&error byAccessor:^(NSURL *newURL) {
			BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[newURL path]];
			
			if (!fileExists) {
				joinAction = kOverwriteAndSeed;
			}
			else {
#if !TARGET_OS_IPHONE
				joinAction = NSRunAlertPanel(NSLocalizedString(@"There is already DayMap data on iCloud", @"error dialog"),
								NSLocalizedString(@"This is already DayMap data on iCloud. Would you like to merge it or overwrite it?", @"error dialog"),
								NSLocalizedString(@"Merge", @"error dialog"), NSLocalizedString(@"Cancel", @"error dialog"), NSLocalizedString(@"Overwrite", @"error dialog"));
				if (kOverwriteAndSeed == joinAction) {
					NSInteger confirm = NSRunAlertPanel(NSLocalizedString(@"Overwrite DayMap data on iCloud?", @"error dialog"),
									NSLocalizedString(@"Overwrite data on iCloud with your current DayMap data?\nThis can not be undone.", @"error dialog"),
									NSLocalizedString(@"Don't Overwrite", @"error dialog"), NSLocalizedString(@"Overwrite", @"error dialog"), nil);
					if (NSAlertDefaultReturn == confirm) {
						joinAction = kCancel;
					}
				}
#else
				joinAction = kMerge;
#endif
			}
		}];
		if (error) {
#if !TARGET_OS_IPHONE
			NSRunAlertPanel(NSLocalizedString(@"Could not enable iCloud", @"error dialog"),
							NSLocalizedString(@"The system is not permitting access to the DayMap iCloud file. This could be caused by a sync in progress. If this problem persists, wait a few minutes or reboot your Mac.", @"error dialog"),
							NSLocalizedString(@"OK", @"error dialog"), nil, nil);
#endif
			NSLog(@"Error performing coordinated read at url '%@': %@", [self ubiquitousStoreURL], error);
			return;
		}
		
		if (kCancel == joinAction) {
			return;
		}
		
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PREF_USE_ICLOUD_STORAGE]; // save pref change

		[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
		[self disableFilePresenter];
		[self unloadPersistentStore];
		[self tearDownCoreDataStack];
		if (kOverwriteAndSeed == joinAction) {
			// Don't Assume local is already loaded, and we need it to seed from
			[self seedUbiquitousPersistentStore];
		}
		[self setupCoreDataStack];
		[self loadUbiquitousPersistentStore];
		[self mergeConflicts];
		
		if (kMerge == joinAction) {
			BOOL success = [self mergeDayMapStoreAtURL:[self localStoreURL]];
			if (!success) {
#if !TARGET_OS_IPHONE
				NSRunAlertPanel(NSLocalizedString(@"Unable to merge iCloud data", @"error dialog"),
								NSLocalizedString(@"There was a problem merging local data with iCloud data.\nYou may need try again and overwrite iCloud data instead.", @"error dialog"),
								NSLocalizedString(@"OK", @"error dialog"), nil, nil);
#else
				[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to merge iCloud data", @"error dialog") message:NSLocalizedString(@"There was a problem merging local data with iCloud data.\nYou may need try again and overwrite iCloud data instead.", @"error dialog") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"error dialog") otherButtonTitles:nil] show];
#endif
			}
		}

		if (kOverwriteAndSeed == joinAction) {
			// Clear tombstones since we are starting from fresh
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:[NSEntityDescription entityForName:@"Tombstone" inManagedObjectContext:DMCurrentManagedObjectContext]];
			NSError *error;
			NSArray *tombstones = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
			for (NSManagedObject *obj in [tombstones copy]) {
				[DMCurrentManagedObjectContext deleteObject:obj];
			}
		}
		
		[self enableFilePresenterForURL:[self presentedItemURL]];
		[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
	}
	else { // Turn off iCloud
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PREF_USE_ICLOUD_STORAGE]; // save pref change
		
		DLog(@"before inbox count = %ld", (unsigned long)DMCurrentManagedObjectContext.dayMap.inbox.children.count);

		[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
		[self disableFilePresenter];
		[self unloadPersistentStore];
		[self tearDownCoreDataStack];

		[self setupCoreDataStack];
		[self loadLocalPersistentStore];
		[self mergeConflicts];
		
		BOOL success = [self mergeDayMapStoreAtURL:[self ubiquitousStoreURL]];
		if (!success) {
			NSLog(@"There was a problem merging local data.");
		}
		
		[self enableFilePresenterForURL:[self presentedItemURL]];
		[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
	}
}

- (NSManagedObjectContext *)readOnlyContextFromStoreAtURL:(NSURL *)storeURL persistentStoreCoordinator:(NSPersistentStoreCoordinator **)coordinator {
	// Open the conflict in a core data stack -- punt if cant open the conflict. -- may be an old format?
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DayMap" withExtension:@"momd"];
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	if (!managedObjectModel) {
		DLog(@"%@:%@ Error resolving conflict. No model to generate a store from.", [self class], NSStringFromSelector(_cmd));
		return NO;
	}
	NSManagedObjectContext *conflictContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	NSPersistentStoreCoordinator *conflictCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	if (!conflictCoordinator) {
		DLog(@"%@:%@ Error resolving conflict. Could not create persistent store coordinator.", [self class], NSStringFromSelector(_cmd));
		return NO;
	}
	[conflictContext performBlockAndWait:^{
		[conflictContext setPersistentStoreCoordinator:conflictCoordinator];
		[conflictContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	}];
	
	// Open the conflicted core data file
	BOOL __block errorOpeningStore = NO;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSReadOnlyPersistentStoreOption, nil];
	
	[conflictCoordinator performBlockAndWait:^{
		NSError *psError = nil;
		NSPersistentStore *conflictPersistentStore = [conflictCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:storeURL options:options error:&psError];
		if (!conflictPersistentStore) {
			DLog(@"%@:%@ Error resolving conflict. Could not open persistent store. %@", [self class], NSStringFromSelector(_cmd), psError);
			errorOpeningStore = YES;
		}
	}];
	
	if (errorOpeningStore) {
		return nil;
	}
	
	*coordinator = conflictCoordinator;
	return conflictContext;
}

- (BOOL)doesContext:(DayMapManagedObjectContext *)context differSubstantiallyFromStoreAtURL:(NSURL *)storeURL {
	NSPersistentStoreCoordinator *conflictCoordinator;
	NSManagedObjectContext *conflictContext = [self readOnlyContextFromStoreAtURL:storeURL persistentStoreCoordinator:&conflictCoordinator];
	if (!conflictContext) {
		return YES;
	}
	
	BOOL differs = NO;
	
	// Check for matching Data Model Version
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"DayMap" inManagedObjectContext:conflictContext]];
	NSError *fetchError;
	NSArray *result = [conflictContext executeFetchRequest:fetchRequest error:&fetchError];
	DayMap *conflictDayMap = [result lastObject];
	if (nil == conflictDayMap) {
		DLog(@"Conflict file is valid store but contains no DayMap object.");
		differs = YES;
	}
	
	if (!differs && ![conflictDayMap.dataModelVersion isEqualToNumber:context.dayMap.dataModelVersion]) {
		DLog(@"Conflicts are from different data model versions. Not merging.");
		differs = YES;
	}
	
	if (!differs) {
		// For now we will simply look for 15% or more change in number of tasks. It's a quick test
		fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:context]];
		result = [context executeFetchRequest:fetchRequest error:&fetchError];
		double numberOfTasksInContext = result.count;
		
		fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:conflictContext]];
		result = [conflictContext executeFetchRequest:fetchRequest error:&fetchError];
		double numberOfTasksInConflictContext = result.count;
		
		if (MAX(numberOfTasksInContext, numberOfTasksInConflictContext) > 0) {
			if (MIN(numberOfTasksInContext, numberOfTasksInConflictContext) / MAX(numberOfTasksInContext, numberOfTasksInConflictContext) < 0.85) {
				differs = YES;
			}
		}
	}
	
	// Close
	[conflictCoordinator performBlockAndWait:^{
		for (NSPersistentStore *store in [[conflictCoordinator persistentStores] copy]) {
			NSError *psError = nil;
			if (![conflictCoordinator removePersistentStore:store error:&psError]) {
				DLog(@"Error removing persistent store = %@", psError);
			}
		}
	}];

	return differs;
}

- (void)mergeConflicts
{
	NSError *error = nil;
	NSMutableArray *conflictsToMerge = [NSMutableArray new];
	NSMutableArray *conflictsToMergeSavedURLs = [NSMutableArray new];
	NSURL *dataFileURL = [self presentedItemURL];
	[[[NSFileCoordinator alloc] initWithFilePresenter:self] coordinateReadingItemAtURL:dataFileURL options:0 error:&error byAccessor:^(NSURL *newURL) {
		//		NSArray *otherVersions = [NSFileVersion otherVersionsOfItemAtURL:newURL];
		NSArray *conflicts = [[NSFileVersion unresolvedConflictVersionsOfItemAtURL:newURL] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:YES]]];
		NSLog(@"Detected %ld Conflict(s)...", (unsigned long)conflicts.count);

		for (NSFileVersion *version in conflicts) {
			NSString *versionDescription = [NSString stringWithFormat:@"%@ (%@, %@) %@", version.localizedName, version.localizedNameOfSavingComputer, version.conflict ? @"Conflicted" : @"Non-Conflict", version.modificationDate];

			NSURL *toURL = [[self.conflictFilesDirectory URLByAppendingPathComponent:versionDescription] URLByAppendingPathExtension:[dataFileURL pathExtension]];
			NSError *copyError = nil;
			[[NSFileManager defaultManager] removeItemAtURL:toURL error:NULL];
			NSLog(@"Copying %@...", versionDescription);
			BOOL success = [[NSFileManager defaultManager] copyItemAtURL:version.URL toURL:toURL error:&copyError];
			if (!success) {
				NSLog(@"Error saving conflict version to URL: %@\n%@, %@", toURL, versionDescription, copyError);
				continue;
			}
			[conflictsToMerge addObject:version];
			[conflictsToMergeSavedURLs addObject:toURL];
		}
	}];

	for (NSInteger index = 0; index < conflictsToMerge.count; index++) {
		@autoreleasepool {
			NSFileVersion *version = conflictsToMerge[index];
			NSURL *conflictURL = conflictsToMergeSavedURLs[index];

			NSString *versionDescription = [NSString stringWithFormat:@"%@ (%@, %@) %@", version.localizedName, version.localizedNameOfSavingComputer, version.conflict ? @"Conflicted" : @"Non-Conflict", version.modificationDate];

			// Merge with current MOC
			NSLog(@"Merging conflict %@...", versionDescription);
			@try {
				if (![self mergeDayMapStoreAtURL:conflictURL]) {
					//TODO: failure
					continue;
					// Still resolve iCloud conflict file?
				}
			}
			@catch (NSException *exception) {
				NSLog(@"Exception merging data stores: %@", exception);
				continue;
			}

			NSLog(@"Merge completed.");
			
			// Resolve conflict file
			[[[NSFileCoordinator alloc] initWithFilePresenter:self] coordinateWritingItemAtURL:dataFileURL options:0 error:&error byAccessor:^(NSURL *newURL) {
				version.resolved = YES;
				NSError *removeError;
				if (![version removeAndReturnError:&removeError]) {
					NSLog(@"Error removing conflict version: %@", removeError);
				}
			}];
			
			// Move to attic
			NSURL *toAtticURL = [self.conflictAtticFilesDirectory URLByAppendingPathComponent:[conflictURL lastPathComponent]];
			NSError *moveError = nil;
			[[NSFileManager defaultManager] moveItemAtURL:conflictURL toURL:toAtticURL error:&moveError];
		}
	}
	
	NSLog(@"Done Merging Conflicts.\n");
}

- (BOOL)mergeDayMapStoreAtURL:(NSURL *)conflictURL
{
	NSPersistentStoreCoordinator *conflictCoordinator;
	NSManagedObjectContext *conflictContext = [self readOnlyContextFromStoreAtURL:conflictURL persistentStoreCoordinator:&conflictCoordinator];
	if (!conflictContext) {
		return NO;
	}
	
	// Now have valid context that is open. Iterate contents and merge
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"DayMap" inManagedObjectContext:conflictContext]];
	NSError *fetchError;
	NSArray *result = [conflictContext executeFetchRequest:fetchRequest error:&fetchError];
	DayMap *conflictDayMap = [result lastObject];
	if (nil == conflictDayMap) {
		DLog(@"Conflict file is valid store but contains no DayMap object.");
		return YES;
	}
	
	// TODO:
	// use UUID for isEqual:
	// use UUID for all uses of ObjectID
	// use UUID for existingObjectWithID --> existingObjectWithUUID (predicate search instead)
	// nextTaskToEdit
	// existingObjectsWithIDs
	// managedObjectIDForURIRepresentation
	// URIRepresentation
	// NSManagedObjectID
	
	
	NSLog(@"conflictDayMap %@", [conflictDayMap debugDescription]);
	NSLog(@"dayMap %@", [DMCurrentManagedObjectContext.dayMap debugDescription]);
	if (![conflictDayMap.dataModelVersion isEqualToNumber:DMCurrentManagedObjectContext.dayMap.dataModelVersion]) {
		DLog(@"Conflicts are from different data model versions. Not merging.");
		return YES;
	}
	
//	if (![conflictDayMap.uuid isEqual:DMCurrentManagedObjectContext.dayMap.uuid]) {
//		DLog(@"Different DayMap object. Combining projects and inbox.");
		for (NSManagedObject *project in [conflictDayMap.projects copy]) {
			@autoreleasepool {
				[project setValue:nil forKey:@"parent"];
				[project setValue:nil forKey:@"dayMap"];
				
				NSManagedObject *ourProject = [DMCurrentManagedObjectContext objectWithUUID:[project valueForKey:@"uuid"]];
				ourProject = WSMergeObjectIntoObjectInContext(project, ourProject, DMCurrentManagedObjectContext);

				if ([[[ourProject entity] name] isEqualToString:@"Tombstone"]) {
					continue;
				}

				NSMutableSet *projects = [DMCurrentManagedObjectContext.dayMap mutableSetValueForKey:@"projects"];
				[projects addObject:ourProject];
			}
		}
		for (NSManagedObject *task in [conflictDayMap.inbox.children copy]) {
			@autoreleasepool {
				[task setValue:nil forKey:@"parent"];
				
				NSManagedObject *ourTask = [DMCurrentManagedObjectContext objectWithUUID:[task valueForKey:@"uuid" ]];
				ourTask = WSMergeObjectIntoObjectInContext(task, ourTask, DMCurrentManagedObjectContext);

				if ([[[ourTask entity] name] isEqualToString:@"Tombstone"]) {
					continue;
				}

				NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
				[tasks addObject:ourTask];
			}
		}
//	}
//	else {
//		DLog(@"Same DayMap object. Merging items.");
//		for (NSManagedObject *project in [conflictDayMap.projects copy]) {
//			@autoreleasepool {
//				NSManagedObject *ourProject = [DMCurrentManagedObjectContext objectWithUUID:[project valueForKey:@"uuid"]];
//				DLog(@"remoteProject = %@, ourProject = %@", [project valueForKey:@"name"], ourProject);
//				WSMergeObjectIntoObjectInContext(project, ourProject, DMCurrentManagedObjectContext);
//			}
//		}
//		for (NSManagedObject *task in [conflictDayMap.inbox.children copy]) {
//			@autoreleasepool {
//				NSManagedObject *ourTask = [DMCurrentManagedObjectContext objectWithUUID:[task valueForKey:@"uuid" ]];
//				DLog(@"remoteTask  = %@, ourTask = %@", [task valueForKey:@"name"], ourTask);
//				WSMergeObjectIntoObjectInContext(task, ourTask, DMCurrentManagedObjectContext);
//			}
//		}
//	}

	// For all conflictDayMap tomstones
	// Find local objects with tombstone.uuid (which are not tombstones themselves), and remove them.
	NSFetchRequest *tombstoneFetchRequest = [[NSFetchRequest alloc] init];
	[tombstoneFetchRequest setEntity:[NSEntityDescription entityForName:@"Tombstone" inManagedObjectContext:conflictContext]];
	NSError *error;
	NSArray *tombstoneResult = [conflictContext executeFetchRequest:tombstoneFetchRequest error:&error];
	for (NSManagedObject *tombstone in tombstoneResult) {
		NSManagedObject *ourObject = [DMCurrentManagedObjectContext objectWithUUID:[tombstone valueForKey:@"uuid"]];
		if (ourObject && ![[[ourObject entity] name] isEqualToString:@"Tombstone"]) {
			[DMCurrentManagedObjectContext deleteObject:ourObject];
		}
	}
	
	// Close
	[conflictCoordinator performBlockAndWait:^{
		for (NSPersistentStore *store in [[conflictCoordinator persistentStores] copy]) {
			NSError *psError = nil;
			if (![conflictCoordinator removePersistentStore:store error:&psError]) {
				DLog(@"Error removing persistent store = %@", psError);
			}
		}
	}];
	
	return YES;
}

#pragma mark - NSFilePresenter (for iCloud)

- (NSURL *)presentedItemURL {
	return _presentedItemURL;
}

- (NSOperationQueue *)presentedItemOperationQueue {
	return _presentedItemOperationQueue;
}

- (void)enableFilePresenterForURL:(NSURL *)url
{
	DLog(@"enableFilePresenterForURL(%@)", url);
    // Switch on the file presenter
	_presentedItemOperationQueue = [NSOperationQueue mainQueue];
	_presentedItemURL = url;
	[NSFileCoordinator addFilePresenter:self];
}

- (void)disableFilePresenter
{
	DLog(@"disableFilePresenter");
    [NSFileCoordinator removeFilePresenter:self];
    _presentedItemOperationQueue = nil;
}

- (void)presentedItemDidChange
{
	DLog(@"presentedItemDidChange. URL = %@", _presentedItemURL);
	
	if ([DMCurrentManagedObjectContext hasBeenModifiedOnDiskSinceLastSave]) {
		[DMCurrentManagedObjectContext forceBackup]; // Lets save a backup here because iCloud is very buggy

		// Check for conflicts
		__block BOOL hasConflicts = NO;
		NSError *error = nil;
		NSURL *dataFileURL = [self presentedItemURL];
		[[[NSFileCoordinator alloc] initWithFilePresenter:self] coordinateReadingItemAtURL:dataFileURL options:0 error:&error byAccessor:^(NSURL *newURL) {
			NSArray *conflicts = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:newURL];
			if (conflicts.count > 0) {
				hasConflicts = YES;
			}
		}];
		
		if (hasConflicts) {
			DLog(@"Merging conflicts...");
			[self mergeConflicts];
		}

		NSURL *swapURL = [[self presentedItemURL] URLByAppendingPathExtension:@"swap"];
		[[NSFileManager defaultManager] removeItemAtURL:swapURL error:NULL];
		[[NSFileManager defaultManager] copyItemAtURL:[self presentedItemURL] toURL:swapURL error:NULL];
		BOOL storesDifferSubstantially = [self doesContext:DMCurrentManagedObjectContext differSubstantiallyFromStoreAtURL:swapURL];
		
		if ([DMCurrentManagedObjectContext hasChanges] || storesDifferSubstantially) {
			if (storesDifferSubstantially) {
				DLog(@"Stores differ subtantially");
			}
			if ([DMCurrentManagedObjectContext hasChanges]) {
				DLog(@"Have local changes");
			}
			DLog(@"merging with remote changes...");
			BOOL success = [self mergeDayMapStoreAtURL:swapURL];
			DLog(success ? @"\tsuccess." : @"\tfailed.");

			NSError *error = nil;
			NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
			[coordinator coordinateReadingItemAtURL:[self presentedItemURL] options:0 error:&error byAccessor:^(NSURL *newURL) {
				[DMCurrentManagedObjectContext updateHash];
			}];
			if (error) {
				DLog(@"Error coordinating read to update hash");
			}
		}
		else {
			DLog(@"No local changes, reloading from remote.");
			[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
			[self disableFilePresenter];
			[self unloadPersistentStore];
			[self tearDownCoreDataStack];

			[self setupCoreDataStack];
			[self loadPersistentStoreAtPresentedItemURL];
			[self enableFilePresenterForURL:[self presentedItemURL]];
			[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
		}
	}
	DLog(@"Finished presentedItemDidChange.");
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
	DLog(@"presentedItemDidMoveToURL: %@", newURL);
	_presentedItemURL = newURL;
}

#pragma mark - managedObjectContextObjectsDidChangeNotification
- (void)managedObjectContextObjectsDidChangeNotification:(NSNotification *)notification
{
	@try {
		DLog(@"managedObjectContextObjectsDidChangeNotification");

		if ([notification object] != DMCurrentManagedObjectContext) {
			return;
		}

        NSMutableArray *parentsToUpdate = [NSMutableArray new];

		//The notification object is the managed object context. The userInfo dictionary contains the following keys: NSInsertedObjectsKey, NSUpdatedObjectsKey, and NSDeletedObjectsKey.

		// Send notification on Task deleted, or scheduled date change
		// This is needed for the week view to properly update itself, since there is no set in core data it can actually observe
		NSSet *deleted = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
		NSSet *changed = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
		NSSet *inserted = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
		NSSet *refreshed = [[notification userInfo] objectForKey:NSRefreshedObjectsKey];

		//	NSSet *allUpdated = [NSSet set];
		//	if (changed) allUpdated = [allUpdated setByAddingObjectsFromSet:changed];
		//	if (inserted) allUpdated = [allUpdated setByAddingObjectsFromSet:inserted];
		//	if (refreshed) allUpdated = [allUpdated setByAddingObjectsFromSet:refreshed];

		BOOL shouldUpdateWeekView = NO;

		// Objects were deleted
		for (NSManagedObject *obj in deleted) {
            DLog(@"---DELETED---");
            DLog(@"obj = %@", [obj description]);
			if ([[[obj entity] name] isEqualToString:@"Task"]) {
				shouldUpdateWeekView = YES;
				break;
			}

			if ([[[obj entity] name] isEqualToString:@"RecurrenceRule"]) {
				shouldUpdateWeekView = YES;
				break;
			}

            if ([self.selectedTasks containsObject:[obj valueForKey:@"uuid"]]) {
                self.selectedTasks = nil;
            }

            if ([self.selectedProject isEqual:[obj valueForKey:@"uuid"]]) {
                self.selectedProject = nil;
            }
		}

		// Objects were inserted
		for (NSManagedObject *obj in inserted) {
			DLog(@"---INSERTED---");
			//			DLog(@"obj = %@", [obj description]);
			//			DLog(@"changedValuesForCurrentEvent = %@", [[obj changedValuesForCurrentEvent] description]);
			//			DLog(@"changedValues = %@", [[obj changedValues] description]);

			shouldUpdateWeekView = YES;

			if ([obj.entity.name isEqualToString:@"Project"]) {
                if (![parentsToUpdate containsObject:[obj valueForKey:@"uuid"]]) [parentsToUpdate addObject:[obj valueForKey:@"uuid"]];
				// TODO - need to refresh projects view? Or do all views bind to dayMap.projects already?
			}
			if ([obj.entity.name isEqualToString:@"Task"]) {
				NSManagedObject *parent = [obj valueForKey:@"parent"];
                if (![parentsToUpdate containsObject:[parent valueForKey:@"uuid"]]) [parentsToUpdate addObject:[parent valueForKey:@"uuid"]];
			}
		}

		// Objects were refreshed --> usually because iCloud synced in background
		for (NSManagedObject *obj in refreshed) {
			DLog(@"---REFRESHED---");
			//			DLog(@"obj = %@", [obj description]);
			//			DLog(@"changedValuesForCurrentEvent = %@", [[obj changedValuesForCurrentEvent] description]);
			//			DLog(@"changedValues = %@", [[obj changedValues] description]);
			//		NSDictionary *changedValues = [obj changedValuesForCurrentEvent];
			//		NSArray *allKeys = [changedValues allKeys];

			shouldUpdateWeekView = YES;

			if ([obj.entity.name isEqualToString:@"Project"]) {
                if (![parentsToUpdate containsObject:[obj valueForKey:@"uuid"]]) [parentsToUpdate addObject:[obj valueForKey:@"uuid"]];
				[DMCurrentManagedObjectContext.dayMap willChangeValueForKey:@"projects"]; // update sorting if needed
				[DMCurrentManagedObjectContext.dayMap didChangeValueForKey:@"projects"];
			}
			if ([obj.entity.name isEqualToString:@"Task"]) {
				NSManagedObject *parent = [obj valueForKey:@"parent"];
                if (![parentsToUpdate containsObject:[parent valueForKey:@"uuid"]]) [parentsToUpdate addObject:[parent valueForKey:@"uuid"]];
			}
		}

		// Objects were changed
		for (NSManagedObject *obj in changed) {
			DLog(@"---CHANGED---");
			DLog(@"obj = %@", [obj description]);
			//			DLog(@"changedValuesForCurrentEvent = %@", [[obj changedValuesForCurrentEvent] description]);
			//			DLog(@"changedValues = %@", [[obj changedValues] description]);

			NSDictionary *changedValues = [obj changedValuesForCurrentEvent];
			NSArray *allKeys = [changedValues allKeys];
			if (!shouldUpdateWeekView && ([allKeys containsObject:@"scheduledDate"] ||
										  [allKeys containsObject:@"parent"] ||
										  [allKeys containsObject:@"color"] ||
										  [allKeys containsObject:@"repeat"] ||
										  [allKeys containsObject:@"endAfterCount"] ||
										  [allKeys containsObject:@"endAfterDate"] ||
										  [allKeys containsObject:@"frequency"] ||
										  [allKeys containsObject:@"repeat.completions"] ||
										  [allKeys containsObject:@"repeat.exceptions"] ||
										  [allKeys containsObject:@"archived"] ||
										  [allKeys containsObject:@"sortIndexInDay"])) {
				shouldUpdateWeekView = YES;
			}
			if ([allKeys containsObject:@"children"]) {
                if (![parentsToUpdate containsObject:[obj valueForKey:@"uuid"]]) [parentsToUpdate addObject:[obj valueForKey:@"uuid"]];
			}
			if ([allKeys containsObject:@"sortIndex"] && [obj.entity.name isEqualToString:@"Task"]) {
				NSManagedObject *parent = [obj valueForKey:@"parent"];
                if (![parentsToUpdate containsObject:[parent valueForKey:@"uuid"]]) [parentsToUpdate addObject:[parent valueForKey:@"uuid"]];
			}
		}

		if (shouldUpdateWeekView) {
			DLog(@"Sending notification DMUpdateWeekView");
			//			dispatch_async(dispatch_get_main_queue(), ^(void){
			[[NSNotificationCenter defaultCenter] postNotificationName:DMUpdateWeekViewNotification object:nil];
			//			});
		}

        // Send notifications now
        for (id parent in parentsToUpdate) {
            DLog(@"Sending DMChildrenDidChangeForParent for %@", parent);
            [[NSNotificationCenter defaultCenter] postNotificationName:DMChildrenDidChangeForParentNotification object:parent userInfo:nil];
        }
        DLog(@"Finished managedObjectContextObjectsDidChangeNotification");
	}
	@catch (NSException *exception) {
		NSLog(@"Exception in managedObjectContextObjectsDidChangeNotification: %@", [exception description]);
	}
}

#pragma mark - Projects Data Accessors

- (NSSet *)selectedTasks
{
	@synchronized(self) {
		return _selectedTasks;
	}
}

- (void)setSelectedTasks:(NSSet *)selectedTasks
{
	//DLog(@"setSelectedTasks %@", [selectedTasks description]);
	@synchronized(self) {
		[self willChangeValueForKey:@"selectedProject"];
		_selectedProject = nil; // clear project selection
		[self didChangeValueForKey:@"selectedProject"];

		_selectedTasks = selectedTasks;
	}
}

- (NSString *)selectedProject
{
	@synchronized(self) {
		return _selectedProject;
	}
}

- (void)setSelectedProject:(NSString *)selectedProject
{
	@synchronized(self) {
		[self willChangeValueForKey:@"selectedTasks"];
		_selectedTasks = nil; // clear project selection
		[self didChangeValueForKey:@"selectedTasks"];

		_selectedProject = selectedProject;
	}
}

#pragma mark - Misc

- (NSUndoManager *)undoManager {
	if (nil == _undoManager) {
		_undoManager = [[NSUndoManager alloc] init];
	}
	return _undoManager;
}

- (NSURL *)applicationFilesDirectory {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *dayMapSupportDirPath = nil;
#if !TARGET_OS_IPHONE
	NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	dayMapSupportDirPath = [appSupportURL URLByAppendingPathComponent:@"DayMap"];
#else
    dayMapSupportDirPath = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
#endif
	
	NSError *error = nil;
	BOOL isDir;
	if (![fileManager fileExistsAtPath:[dayMapSupportDirPath path] isDirectory:&isDir]) {
		if (![fileManager createDirectoryAtPath:[dayMapSupportDirPath path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory: %@", error);
			return nil;
		}
	}
	else if (!isDir) {
		NSLog(@"Expected a folder to store application data, found a file (%@).", [dayMapSupportDirPath path]);
		return nil;
	}
	
	return dayMapSupportDirPath;
}

- (NSURL *)applicationGroupSharedFilesDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *appGroupName = @"2WFZT4HWJN.com.whetstoneapps.daymap-suite";

    NSURL *groupContainerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:appGroupName];

	NSError *error = nil;
	BOOL isDir;
	if (![fileManager fileExistsAtPath:[groupContainerURL path] isDirectory:&isDir]) {
		if (![fileManager createDirectoryAtURL:groupContainerURL withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory: %@", error);
			return nil;
		}
	}
	else if (!isDir) {
		NSLog(@"Expected a folder to store application data, found a file (%@).", groupContainerURL);
		return nil;
	}

	return groupContainerURL;
}

- (NSURL *)backupFilesDirectory
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *dayMapBackupDirPath = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"Backups"];
	
	NSError *error = nil;
	BOOL isDir;
	if (![fileManager fileExistsAtPath:[dayMapBackupDirPath path] isDirectory:&isDir]) {
		if (![fileManager createDirectoryAtPath:[dayMapBackupDirPath path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory: %@", error);
			return nil;
		}
	}
	else if (!isDir) {
		NSLog(@"Expected a folder to store application data backups, found a file (%@).", [dayMapBackupDirPath path]);
		return nil;
	}
	
	return dayMapBackupDirPath;
}

- (NSURL *)conflictFilesDirectory
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *dayMapConflictDirPath = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"Conflicts"];
	
	NSError *error = nil;
	BOOL isDir;
	if (![fileManager fileExistsAtPath:[dayMapConflictDirPath path] isDirectory:&isDir]) {
		if (![fileManager createDirectoryAtPath:[dayMapConflictDirPath path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory: %@", error);
			return nil;
		}
	}
	else if (!isDir) {
		NSLog(@"Expected a folder to store application data conflicts, found a file (%@).", [dayMapConflictDirPath path]);
		return nil;
	}
	
	return dayMapConflictDirPath;
}

- (NSURL *)conflictAtticFilesDirectory
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *dayMapConflictAtticDirPath = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"Conflicts/Attic"];
	
	NSError *error = nil;
	BOOL isDir;
	if (![fileManager fileExistsAtPath:[dayMapConflictAtticDirPath path] isDirectory:&isDir]) {
		if (![fileManager createDirectoryAtPath:[dayMapConflictAtticDirPath path] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating directory: %@", error);
			return nil;
		}
	}
	else if (!isDir) {
		NSLog(@"Expected a folder to store application data conflicts attic, found a file (%@).", [dayMapConflictAtticDirPath path]);
		return nil;
	}
	
	return dayMapConflictAtticDirPath;
}

- (NSURL *)oldUbiquitousStoreURL {
	NSURL *ubiquityContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"2WFZT4HWJN.com.whetstoneapps.daymap"];
	return [ubiquityContainerURL URLByAppendingPathComponent:@"DayMap.b_storedata"];
}

- (NSURL *)ubiquitousStoreURL
{
	NSURL *ubiquityContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
//	NSURL *ubiquityContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"2WFZT4HWJN.com.whetstoneapps.daymap"];
	return [ubiquityContainerURL URLByAppendingPathComponent:@"DayMap.b_storedata"];
}

- (NSURL *)localStoreURL
{
#ifdef TARGET_DAYMAP_LITE
	return [self liteLocalStoreURL];
#else
	return [[self applicationFilesDirectory] URLByAppendingPathComponent:@"DayMap.b_storedata"];
#endif
}

- (NSURL *)liteLocalStoreURL {
	return [[self applicationGroupSharedFilesDirectory] URLByAppendingPathComponent:@"DayMapLite.b_storedata"];
}

- (IBAction)openWhetstoneAppsDotComSupport:(id)sender {
#if !TARGET_OS_IPHONE
	[[NSWorkspace sharedWorkspace] openURL:DMWhetstoneAppsSupportURL];
#endif
}

- (NSArray *)tasksForDay:(NSDate *)day
{
	static NSCache *__cache = nil;
	if (!__cache) {
		__cache = [[NSCache alloc] init];
	}

	if (!DMCurrentManagedObjectContext) return nil;
	if (!day) return nil;

	// Return cache if day and context has not changed
	if ([DMCurrentManagedObjectContext lastHash] &&
		[[__cache objectForKey:@"MOCHash"] isEqualToString:[DMCurrentManagedObjectContext lastHash]] &&
		[__cache objectForKey:@"MOC"] == DMCurrentManagedObjectContext &&
		![DMCurrentManagedObjectContext hasChanges]) {

		// Cache is valid. Attempt to look up cached day.
		NSArray *result = [__cache objectForKey:day];
		if (result) {
			return result;
		}
	}
	else { // MOC has been updated. Cache is invalid.
		[__cache removeAllObjects];
		if ([DMCurrentManagedObjectContext lastHash]) {
			[__cache setObject:[DMCurrentManagedObjectContext lastHash] forKey:@"MOCHash"];
			[__cache setObject:DMCurrentManagedObjectContext forKey:@"MOC"];
		}
	}

	NSError *error;
	NSMutableArray *tasksForDay = [NSMutableArray new];
	
	// Create some sort descriptors for later use
	NSArray *sortByIndexInDayDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"sortIndexInDay" ascending:YES]];
	
	// Fetch the tasks with scheduled date of day
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
	day = [day dateQuantizedToDay];
	NSDate *startDate = day;
	NSDate *endDate = [startDate dateByAddingDays:1];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(scheduledDate >= %@) AND (scheduledDate < %@) AND (repeat == nil)", startDate, endDate];
	[fetchRequest setSortDescriptors:sortByIndexInDayDescriptors];
	[tasksForDay addObjectsFromArray:[DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error]];

	if (![[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_ARCHIVED_PROJECTS]) {
		for (Task *task in [tasksForDay copy]) {
			Project *project = [task rootProject];
			if (project && [project.archived boolValue]) {
				[tasksForDay removeObject:task];
			}
		}
	}

	// Fetch recurring tasks that land on day
	for (id obj in [self recurringTasksMatchingDay:day]) {
		if (![tasksForDay containsObject:obj]) {
			[tasksForDay addObject:obj];
		}
	}

	[__cache setObject:tasksForDay forKey:[day copy]];

	return tasksForDay;
}

- (NSArray *)recurringTasksMatchingDay:(NSDate *)day {
	NSArray *sortByScheduledDateDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"scheduledDate" ascending:YES]];
	NSError *error = nil;

	// Fetch all tasks with scheduled date and recurrence rule and recurrence frequency, sorted by scheduled date
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"scheduledDate != nil AND repeat != nil"];
	[fetchRequest setSortDescriptors:sortByScheduledDateDescriptors];
	NSArray *scheduledRepeatingTasks = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];

	// Get the tasks which recurr on this day according to their recurrence rules
	NSMutableArray *tasks = [WSRecurringTasksMatchingDayIgnoringExceptions(scheduledRepeatingTasks, day, NULL) mutableCopy];

	// Remove recurring tasks with specific exceptions on this day
	for (NSInteger index = tasks.count - 1; index >= 0; index--) {
		Task *task = tasks[index];
		if ([task.repeat hasExceptionForDate:day]) {
			[tasks removeObjectAtIndex:index];
		}
	}
	return tasks;
}

- (NSDate *)completedDateFilter {
	// Subclass to implement
	return nil;
}

- (IBAction)moveOverdueTasksToToday:(id)sender
{
	NSDate *today = [NSDate today];
    NSManagedObjectContext *context = DMCurrentManagedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:context]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(repeat = nil AND scheduledDate < %@ AND completed != %d)", today, TASK_COMPLETED];
    
    NSError *error;
	NSArray *result;
	
	result = [context executeFetchRequest:fetchRequest error:&error];
	
	for (Task *task in result) {
		task.scheduledDate = today;
	}
}

- (void)deleteCompletedTasksOlderThan:(NSDate *)olderThanDate {
	if (!olderThanDate) return;
	
    NSManagedObjectContext *context = DMCurrentManagedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:context]];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(repeat = nil AND completed = %d AND completedDate < %@)", TASK_COMPLETED, olderThanDate];
    
    NSError *error;
	NSArray *result;
	
	result = [context executeFetchRequest:fetchRequest error:&error];
	
	for (Task *task in result) {
		[DMCurrentManagedObjectContext deleteObject:task];
	}
}

@end
