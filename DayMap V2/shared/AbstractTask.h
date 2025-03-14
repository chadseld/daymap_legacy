//
//  AbstractTask.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/10/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AbstractTask;

@interface AbstractTask : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * sortIndex;
@property (nonatomic, retain) NSDate * completedDate;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * sortIndexInDay;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSData * attributedDetails;
@property (nonatomic, retain) AbstractTask *parent;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSSet *attachments;
@property (nonatomic, retain) NSSet *tags;
@end

@interface AbstractTask (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(AbstractTask *)value;
- (void)removeChildrenObject:(AbstractTask *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)addAttachmentsObject:(NSManagedObject *)value;
- (void)removeAttachmentsObject:(NSManagedObject *)value;
- (void)addAttachments:(NSSet *)values;
- (void)removeAttachments:(NSSet *)values;

- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
