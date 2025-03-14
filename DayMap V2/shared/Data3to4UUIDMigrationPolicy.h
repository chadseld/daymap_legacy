//
//  Data3to4UUIDMigrationPolicy.h
//  DayMap
//
//  Created by Chad Seldomridge on 11/20/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Data3to4UUIDMigrationPolicy : NSEntityMigrationPolicy

- (NSString *)createUUID;
- (NSNumber *)dataModelVersion;

@end
