//
//  Task.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/9/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AbstractTask.h"
#import "RecurrenceRule.h"


@interface Task : AbstractTask

@property (nonatomic, retain) NSDate * scheduledDate;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSSet *reminders;
@property (nonatomic, retain) RecurrenceRule *repeat;
@end

@interface Task (CoreDataGeneratedAccessors)

- (void)addRemindersObject:(NSManagedObject *)value;
- (void)removeRemindersObject:(NSManagedObject *)value;
- (void)addReminders:(NSSet *)values;
- (void)removeReminders:(NSSet *)values;

@end
