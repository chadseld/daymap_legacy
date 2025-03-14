//
//  DayMapManagedObjectContext.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/1/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@class DayMap;
@interface DayMapManagedObjectContext : NSManagedObjectContext

@property (strong, readonly) DayMap *dayMap;

- (NSArray *)entityNames;
- (NSSet *)objectsWithUUIDs:(NSSet *)uuids;
- (NSManagedObject *)objectWithUUID:(NSString *)uuid;

- (void)forceBackup;
+ (NSArray *)existingBackupFilesAtURL:(NSURL *)backupFilesDirectory;

- (BOOL)hasBeenModifiedOnDiskSinceLastSave;
- (void)updateHash;
- (NSString *)lastHash;

@end
