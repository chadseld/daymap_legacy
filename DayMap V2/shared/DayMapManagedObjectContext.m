//
//  DayMapManagedObjectContext.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/1/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "DayMapManagedObjectContext.h"
#import "DayMap.h"
#import "Project.h"
#import "MiscUtils.h"
#import "NSString+WS.h"
#if !TARGET_OS_IPHONE
#import "DayMapAppDelegate.h"
#endif


@implementation DayMapManagedObjectContext {
    NSString *_lastSHAHash;
	DayMap *_dayMap;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosave) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoBackup) object:nil];
}

- (DayMap *)dayMap
{
	@synchronized(self) {
		if (nil == _dayMap) {
			DLog(@"Fetching daymap from store");
			
			// Fetch from store
			NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
			[fetchRequest setEntity:[NSEntityDescription entityForName:@"DayMap" inManagedObjectContext:self]];
			NSError *error;
			NSArray *result = [self executeFetchRequest:fetchRequest error:&error];
			
			_dayMap = [result lastObject];
			
			// Create DayMay for the first time if not found in store
			if (nil == _dayMap) {
				DLog(@"Creating daymap for the first time");
				DayMap *dayMap = [NSEntityDescription
								  insertNewObjectForEntityForName:@"DayMap" 
								  inManagedObjectContext:self];
				dayMap.uuid = WSCreateUUID();
				dayMap.inbox = [NSEntityDescription
								insertNewObjectForEntityForName:@"Project" 
								inManagedObjectContext:self];
				dayMap.inbox.uuid = WSCreateUUID();
				dayMap.inbox.name = @"Inbox";
				dayMap.inbox.createdDate = [NSDate date];
				
				dayMap.dataModelVersion = @9;
				
				_dayMap = dayMap;
			}
		}
		
		return _dayMap;
	}
}

- (NSArray *)entityNames {
	// Is there a smarter way to do this? E.g. more generic entity description? From the MOM?
	NSArray *entityNames = @[@"Tombstone",
							 @"Task",
							 @"Project",
							 @"DayMap",
							 @"ProjectDisplayAttributes",
							 @"Reminder",
							 @"Attachment",
							 @"Tag",
							 @"RecurrenceRule",
							 @"RecurrenceCompletion",
							 @"RecurrenceException",
							 @"RecurrenceSortIndex"];
	return entityNames;
}

- (NSManagedObject *)objectWithUUID:(NSString *)uuid
{
	if (nil == uuid) {
		return nil;
	}

	NSArray *entityNames = [self entityNames];
	
	for (NSString *name in entityNames) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:name inManagedObjectContext:self]];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(uuid MATCHES %@)", uuid];
		NSError *error;
		NSArray *result = [self executeFetchRequest:fetchRequest error:&error];
		if (result.count > 0) return [result objectAtIndex:0];
	}

	return nil;
}

- (NSSet *)objectsWithUUIDs:(NSSet *)uuids
{
	NSMutableSet *result = [NSMutableSet new];
	for (NSString *uuid in uuids) {
		NSManagedObject *obj = [self objectWithUUID:uuid];
		if(obj) [result addObject:obj];
	}
	return result;
}

- (BOOL)hasBeenModifiedOnDiskSinceLastSave
{
    __block NSString *currentHash;
    NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:(id<NSFilePresenter>)[NSApp delegate]];
    [coordinator coordinateReadingItemAtURL:[self storeURL] options:0 error:&error byAccessor:^(NSURL *newURL) {
        currentHash = WSSHAFromFileAtURL(newURL);
    }];
    if (error) {
        DLog(@"Error coordinating read for MD5 at URL: %@, %@", [self storeURL], error);
    }
    
    if (!currentHash || !_lastSHAHash) {
        return YES;
    }
    
    return ![_lastSHAHash isEqualToString:currentHash];
}

- (void)updateHash
{
    // We don't coordinate reading here, must call from coordinating block
    _lastSHAHash = WSSHAFromFileAtURL([self storeURL]);
}

- (NSString *)lastHash {
	return _lastSHAHash;
}

- (NSURL *)storeURL
{
    if (nil == self.persistentStoreCoordinator) {
        return nil;
    }
	NSPersistentStore *store = [[self.persistentStoreCoordinator persistentStores] lastObject];
    if (nil == store) {
        return nil;
    }
    
    NSURL *url = [self.persistentStoreCoordinator URLForPersistentStore:store];
    if (nil == url) {
        return nil;
    }
    return url;
}

- (void)processPendingChanges
{
    [super processPendingChanges];
	
	if (self.updatedObjects.count > 0 ||
		self.insertedObjects.count > 0 ||
		self.deletedObjects.count > 0) {
		// Automatically save changes after 5 seconds
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autosave) object:nil];
		[self performSelector:@selector(autosave) withObject:nil afterDelay:5];
		
		// Trigger backup if needed
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoBackup) object:nil];
		[self performSelector:@selector(autoBackup) withObject:nil afterDelay:10];
	}
}

- (BOOL)save:(NSError *__autoreleasing *)error
{
    NSURL *url = [self storeURL];
	if (!url) {
		NSLog(@"No storeURL. Can not save.");
		return NO;
	}
    DLog(@"coordinating save write to URL: %@", url);
	__block BOOL result = NO;
	NSError *coordinatorError = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:(id<NSFilePresenter>)[NSApp delegate]];
    [coordinator coordinateWritingItemAtURL:url options:0 error:&coordinatorError byAccessor:^(NSURL *newURL) {
        result = [super save:error];
        [self updateHash];
		[self createLatestBackup];
    }];
    if (coordinatorError) {
        DLog(@"Error coordinating write at URL '%@': %@", url, coordinatorError);
        *error = coordinatorError;
    }
	
	if (!result) {
#if !TARGET_OS_IPHONE
		NSString *reason = NSLocalizedString(@"There was an error saving your DayMap data. If this problem persists, restart DayMap.", @"error dialog");
		if (coordinatorError) {
			reason = NSLocalizedString(@"There was an error saving your DayMap data. The system is not permitting acces to the DayMap data file. This could be related to iCloud syncing. If this problem persists, restart DayMap or reboot your Mac.", @"error dialog");
		}
		NSRunAlertPanel(NSLocalizedString(@"Error saving data.", @"error dialog"),
						reason,
						NSLocalizedString(@"OK", @"error dialog"), nil, nil);
#endif
	}
	
    return result;
}

- (void)autosave
{
	[self performBlock:^{
		// Save to disk
		NSError *error = nil;
		if (![self save:&error]) {
			if (error) {
				NSLog(@"Whoops, couldn't save: %@, %@, %@", [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"WSErrorSavingContextNotification" object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
			}
		}
		else {
			DLog(@"autosaved");
		}
	}];
}

- (void)forceBackup {
	DLog(@"forceBackup");
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate distantPast] forKey:@"PrefLastBackupDate"];
    [self performBlockAndWait:^{
		[self backupAsync:NO];
	}];

}

- (void)autoBackup
{
    [self performBlock:^{
		[self backupAsync:YES];
		[self removeOldBackups];
	}];
}

- (void)backupAsync:(BOOL)async
{
#if !TARGET_OS_IPHONE
	DLog(@"Beginning backup");
	NSDate *lastBackupDate = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:@"PrefLastBackupDate"];
	if (([[NSDate date] timeIntervalSinceReferenceDate] - [lastBackupDate timeIntervalSinceReferenceDate]) > 24*60*60) {
		
		NSDate *now = [NSDate date];
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd,HH-mm"];
		
		NSString *toFileName = [NSString stringWithFormat:@"DayMap.b_storedata,%@", [dateFormatter stringFromDate:now]];
		NSURL *toURL = [[(DayMapAppDelegate *)[NSApp delegate] backupFilesDirectory] URLByAppendingPathComponent:toFileName];

		
		NSURL *fromURL = [self storeURL];
		if (!fromURL) {
			NSLog(@"No storeURL. Can not backup.");
			return;
		}

		void (^backupBlock)(void) = ^void(void) {
			DLog(@"coordinating backup of URL: %@ to URL: %@", fromURL, toURL);
			NSError *coordinatorError = nil;
			NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:(WSRootAppDelegate *)[NSApp delegate]];
			[coordinator coordinateReadingItemAtURL:fromURL options:0 writingItemAtURL:toURL options:0 error:&coordinatorError byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {

				// Do the file copy
				NSError *error = nil;
				if ([[NSFileManager defaultManager] fileExistsAtPath:[newWritingURL path] isDirectory:NULL]) {
					[[NSFileManager defaultManager] removeItemAtURL:newWritingURL error:&error];
				}
				if (![[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error]) {
					DLog(@"Error copying file to backup %@", error);
				}

				// save new user default
				[[NSUserDefaults standardUserDefaults] setObject:now forKey:@"PrefLastBackupDate"];
			}];

			if (coordinatorError) {
				DLog(@"Error coordinating backup of URL '%@': %@", fromURL, coordinatorError);
			}

			DLog(@"auto-backup completed.");
		};

		if (async) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), backupBlock);
		}
		else {
			backupBlock();
		}
	}
	else {
		DLog(@"auto-backup skipped. Already have a backup for today.");
	}
#endif
}

+ (NSArray *)existingBackupFilesAtURL:(NSURL *)backupFilesDirectory {
#if !TARGET_OS_IPHONE
	NSMutableArray *backupFiles = [NSMutableArray new];

	NSError *error = nil;
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:backupFilesDirectory includingPropertiesForKeys:@[NSURLNameKey, NSURLCreationDateKey, NSFileSize] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
	for (NSURL *file in contents) {
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file path] error:&error];
		
		NSString *filesize = [NSString ws_humanReadableSizeStringForBytes:[[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue]];
		
		NSDate *creationDate;
		if ([[file lastPathComponent] hasSuffix:@"LATEST"]) {
			//creationDate = file creation date
			creationDate = [fileAttributes objectForKey:NSFileCreationDate];
		}
		else {
			// DayMap.b_storedata -- LATEST
			// DayMap.b_storedata,2013-10-24,10-04
			// yyy-MM-dd,HH-mm
			NSArray *nameComponents = [[file lastPathComponent] componentsSeparatedByString:@","];
			
			if (nameComponents.count != 3) {
				NSLog(@"Backup file %@ does not fit naming scheme", [file lastPathComponent]);
				continue;
			}
			
			NSDateFormatter *fileDateFormatter = [[NSDateFormatter alloc] init];
			[fileDateFormatter setDateFormat:@"yyyy-MM-dd,HH-mm"];
			creationDate = [fileDateFormatter dateFromString:[NSString stringWithFormat:@"%@,%@", nameComponents[1], nameComponents[2]]];
		}
		
		if (!creationDate || !filesize || !file) {
			continue;
		}
		
		[backupFiles addObject:@{@"url" : file,
								 @"filename" : [file lastPathComponent],
								 @"creationdate" : creationDate,
								 @"filesize" : filesize}];
	}

	return backupFiles;
#else
    return [NSArray array];
#endif
}

- (void)removeOldBackups
{
#if !TARGET_OS_IPHONE
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSMutableArray *backups = [[DayMapManagedObjectContext existingBackupFilesAtURL:[(WSRootAppDelegate *)[NSApp delegate] backupFilesDirectory]] mutableCopy];
		[backups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationdate" ascending:NO]]];

		while (backups.count > 300) { // keep last n backups
			NSDictionary *backup = [backups lastObject];
			[backups removeLastObject];

			NSError *error = nil;
			if (![[NSFileManager defaultManager] removeItemAtURL:[backup objectForKey:@"url"] error:&error]) {
				NSLog(@"Error removing old backup: %@", error);
				break;
			}
		}
	});
#endif
}

- (void)createLatestBackup
{
#if !TARGET_OS_IPHONE
	DLog(@"Beginning latest-backup");
	
	NSString *toFileName = [NSString stringWithFormat:@"DayMap.b_storedata -- LATEST"];
	NSURL *toURL = [[(DayMapAppDelegate *)[NSApp delegate] backupFilesDirectory] URLByAppendingPathComponent:toFileName];
	
	NSURL *fromURL = [self storeURL];
	if (!fromURL) {
		NSLog(@"No storeURL. Can not backup.");
		return;
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		DLog(@"coordinating backup of URL: %@ to URL: %@", fromURL, toURL);
		NSError *coordinatorError = nil;
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:(WSRootAppDelegate *)[NSApp delegate]];
		[coordinator coordinateReadingItemAtURL:fromURL options:0 writingItemAtURL:toURL options:0 error:&coordinatorError byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
			NSError *error = nil;

			// Delete the old latest
			if (![[NSFileManager defaultManager] removeItemAtURL:toURL error:&error]) {
				DLog(@"Error deleting old latest backup %@", error);
			}

			// Do the file copy
			if (![[NSFileManager defaultManager] copyItemAtURL:newReadingURL toURL:newWritingURL error:&error]) {
				DLog(@"Error copying file to backup %@", error);
			}
		}];

		if (coordinatorError) {
			DLog(@"Error coordinating backup of URL '%@': %@", fromURL, coordinatorError);
		}

		DLog(@"latest-backup completed.");
	});
#endif
}

@end
