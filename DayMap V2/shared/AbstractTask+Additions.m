//
//  AbstractTask+Additions.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/28/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import "AbstractTask+Additions.h"
#import "WSRootAppDelegate.h"
#import "MiscUtils.h"

@implementation AbstractTask (Additions)

- (void)didChangeValueForKey:(NSString *)key
{
    [super didChangeValueForKey:key];
    if ([key isEqualToString:@"children"]) { // also invalidate cache
        _lastChildrenReference = nil;
    }
	if ([key isEqualToString:@"sortIndex"]) {
		[self.parent willChangeValueForKey:@"children"];
		[self.parent didChangeValueForKey:@"children"];
	}
}

- (NSArray *)sortedFilteredChildren
{
	// we have a multi-condition cache invalidation: 
	// 1. check for diff mem address in children
	// 2. check for diff completedDateFilter from app delegate
    // 3. Since children is mutable and often does not change, we check count. This does not catch replace events such as reordering.
    // 4. We watch didChangeValueForKey above
	
	NSDate *completedDateFilter = [(WSRootAppDelegate *)[NSApp delegate] completedDateFilter];
	if (self.children != _lastChildrenReference ||
        self.children.count != _lastChildrenCount ||
        ![completedDateFilter isEqualToDate:_lastCompletedDateFilter]) {
		_sortedFilteredChildren = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(self.children, completedDateFilter, nil, SORT_BY_SORTINDEX);
		_lastChildrenReference = self.children;
        _lastChildrenCount = self.children.count;
		_lastCompletedDateFilter = completedDateFilter;
	}
	return _sortedFilteredChildren;
}

- (NSArray *)breadcrumbs {
	NSMutableArray *crumbs = [NSMutableArray new];

	id root = self;
	id nextUp = nil;
	while ([[[root entity] name] isEqualToString:@"Task"] &&
		   ((nextUp = [root valueForKey:@"parent"]) != nil)) {
		root = nextUp;
		[crumbs insertObject:nextUp atIndex:0];
	}
	return crumbs;
}

- (Project *)rootProject
{
    // If it's a Task, Traverse up the tree to the root project
    // Don't traverse up if it's a Project, because its already a the top.
	id root = self;
    id nextUp = nil;
    while ([[[root entity] name] isEqualToString:@"Task"] && 
           ((nextUp = [root valueForKey:@"parent"]) != nil)) {
        root = nextUp;
    }
	
	if ([[[root entity] name] isEqualToString:@"Task"]) {
		return nil; // should not happen, but sometimes we have bugs where we create orphanned tasks
	}
	
	return root;
}

- (NSAttributedString *)attributedDetailsAttributedString {
	NSData *data = self.attributedDetails;
	if (nil == data) {
		return nil;
	}
	
	NSError *error = nil;
	NSDictionary *options = @{NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType};
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:data options:options documentAttributes:nil error:&error];
	if (!attributedString) {
		NSLog(@"Error converting attributed string: %@", error);
	}

	return attributedString;
}

- (void)setAttributedDetailsAttributedString:(NSAttributedString *)attributedString {
	if (attributedString.length > 0) {
		NSError *error = nil;
		NSData *data = [attributedString dataFromRange:NSMakeRange(0, attributedString.length) documentAttributes:@{NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType} error:&error];
		if (!data) {
			NSLog(@"Error converting attributed string: %@", error);
		}

		self.attributedDetails = data;
	}
	else {
		self.attributedDetails = nil;
	}
}

@end
