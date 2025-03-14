//
//  DayMap.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/30/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Project;

@interface DayMap : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * dataModelVersion;
@property (nonatomic, retain) Project *inbox;
@property (nonatomic, retain) NSSet *projects;
@end

@interface DayMap (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet *)values;
- (void)removeProjects:(NSSet *)values;

@end
