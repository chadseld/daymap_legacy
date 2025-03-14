//
//  DMEventKitBridge.h
//  DayMap
//
//  Created by Chad Seldomridge on 6/20/14.
//  Copyright (c) 2014 Whetstone Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMEventKitBridge : NSObject

- (NSArray *)eventsForDay:(NSDate *)date;
- (NSArray *)eventsForDaysInRangeFromDate:(NSDate *)start toDate:(NSDate *)end;

@end
