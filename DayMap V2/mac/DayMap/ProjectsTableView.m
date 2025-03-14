//
//  ProjectsTableView.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "ProjectsTableView.h"

@implementation ProjectsTableView

/*- (NSRect)adjustScroll:(NSRect)proposedVisibleRect {
	
	// This works but does not animate
	NSInteger columnIndex = [self columnAtPoint:proposedVisibleRect.origin];
//	proposedVisibleRect.origin.x = [self rectOfColumn:columnIndex].origin.x;
//	return proposedVisibleRect;

	
	// This does not work
	[NSAnimationContext beginGrouping];
	NSClipView* clipView = [[self enclosingScrollView] contentView];
	NSPoint newOrigin = [clipView bounds].origin;
	newOrigin.x = [self rectOfColumn:columnIndex].origin.x;
	[[clipView animator] setBoundsOrigin:newOrigin];
	[NSAnimationContext endGrouping];
	
	NSLog(@"adjustScroll");
	return proposedVisibleRect;

}*/

//You can simply animate the bounds-rectangle of the scrollview's clipview, e.g.
@end
