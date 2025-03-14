//
//  RecurrenceRule.h
//  
//
//  Created by Chad Seldomridge on 5/27/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Task;

@interface RecurrenceRule : NSManagedObject

@property (nonatomic, retain) NSNumber * endAfterCount;
@property (nonatomic, retain) NSDate * endAfterDate;
@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSSet *completions;
@property (nonatomic, retain) NSSet *exceptions;
@property (nonatomic, retain) NSSet *sortIndexes;
@property (nonatomic, retain) Task *task;
@end

@interface RecurrenceRule (CoreDataGeneratedAccessors)

- (void)addCompletionsObject:(NSManagedObject *)value;
- (void)removeCompletionsObject:(NSManagedObject *)value;
- (void)addCompletions:(NSSet *)values;
- (void)removeCompletions:(NSSet *)values;

- (void)addExceptionsObject:(NSManagedObject *)value;
- (void)removeExceptionsObject:(NSManagedObject *)value;
- (void)addExceptions:(NSSet *)values;
- (void)removeExceptions:(NSSet *)values;

- (void)addSortIndexesObject:(NSManagedObject *)value;
- (void)removeSortIndexesObject:(NSManagedObject *)value;
- (void)addSortIndexes:(NSSet *)values;
- (void)removeSortIndexes:(NSSet *)values;

@end
