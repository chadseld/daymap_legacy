//
//  Data3to4UUIDMigrationPolicy.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/20/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "Data3to4UUIDMigrationPolicy.h"
#import "MiscUtils.h"

@implementation Data3to4UUIDMigrationPolicy

- (NSString *)createUUID {
	return WSCreateUUID();
}

- (NSNumber *)dataModelVersion {
	return @(4);
}

@end
