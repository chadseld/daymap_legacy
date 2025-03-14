//
//  Data5To6AbstractTaskMigrationPolicy.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/10/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import "Data5To6AbstractTaskMigrationPolicy.h"

@implementation Data5To6AbstractTaskMigrationPolicy

- (NSData *)migrateDetails:(NSString *)sourceDetails {
	if (nil == sourceDetails) {
		return nil;
	}
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:sourceDetails];
	
	if (attributedString.length > 0) {
		NSError *error = nil;
		NSData *data = [attributedString dataFromRange:NSMakeRange(0, attributedString.length) documentAttributes:@{NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType} error:&error];
		if (!data) {
			NSLog(@"Error converting attributed string: %@", error);
		}
		return data;
	}
	
	return nil;
}

@end
