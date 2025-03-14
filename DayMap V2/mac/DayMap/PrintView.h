//
//  PrintView.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrintView : NSViewController

- (void)printProjects:(NSArray *)projects completionHandler:(void(^)(void))completion;
- (void)printWeekAsList:(NSDate *)week numberOfDays:(NSInteger)numberOfDays completionHandler:(void(^)(void))completion;
- (void)printWeek:(NSDate *)week completionHandler:(void(^)(void))completion;

@end
