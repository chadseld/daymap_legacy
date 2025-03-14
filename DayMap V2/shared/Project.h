//
//  Project.h
//  DayMap
//
//  Created by Chad Seldomridge on 6/13/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AbstractTask.h"

@class DayMap, ProjectDisplayAttributes;

@interface Project : AbstractTask

@property (nonatomic, retain) NSNumber * archived;
@property (nonatomic, retain) ProjectDisplayAttributes *displayAttributes;
@property (nonatomic, retain) DayMap *dayMap;

@end
