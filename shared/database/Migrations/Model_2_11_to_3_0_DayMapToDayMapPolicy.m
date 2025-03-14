//
//  Model_2_11_to_3_0_DayMapToDayMapPolicy.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/27/17.
//  Copyright © 2017 Whetstone Apps. All rights reserved.
//

#import "Model_2_11_to_3_0_DayMapToDayMapPolicy.h"

@implementation Model_2_11_to_3_0_DayMapToDayMapPolicy

// This is called by the mapping model rule FUNCTION($entityPolicy, "modifiedDate")
- (NSDate *)modifiedDate {
	return [NSDate date];
}

@end
