//
//  AbstractTask+Additions.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "AbstractTask.h"
#import "Project.h"

@interface AbstractTask (Additions)

- (NSArray *)sortedFilteredChildren;
- (NSArray *)breadcrumbs;
- (Project *)rootProject;

- (NSAttributedString *)attributedDetailsAttributedString;
- (void)setAttributedDetailsAttributedString:(NSAttributedString *)attributedString;

@end

@interface AbstractTask () {
    __weak NSSet *_lastChildrenReference;
    NSUInteger _lastChildrenCount;
	NSDate *_lastCompletedDateFilter;
	NSArray *_sortedFilteredChildren;
}

@end
