//
//  ProjectDisplayAttributes.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/18/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ProjectDisplayAttributes : NSManagedObject

@property (nonatomic, retain) NSData * color;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSDate * modifiedDate;

@end
