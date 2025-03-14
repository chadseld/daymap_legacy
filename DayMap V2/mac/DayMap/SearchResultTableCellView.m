//
//  SearchResultTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/3/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "SearchResultTableCellView.h"
#import "TaskEditPopoverViewController.h"
#import "ProjectEditPopoverViewController.h"
#import "DayMapManagedObjectContext.h"
#import "NSColor+WS.h"
#import "NSDate+WS.h"


@implementation SearchResultTableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	// Do nothing.
	// If we don't override this, the background style will be set on every subview, and text views subtly change their anti-aliasing when selected.
}

- (void)drawRect:(NSRect)dirtyRect {
	[self.projectColor set];
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(2, 2, 5, self.bounds.size.height-4) xRadius:2	yRadius:2] fill];
}

- (void)showPopover
{
    if(![self window]) return;

	NSPopover *popover = [[NSPopover alloc] init];
	popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	popover.behavior = NSPopoverBehaviorSemitransient;
	popover.animates = YES;
	
	NSManagedObject *obj = [DMCurrentManagedObjectContext objectWithUUID:self.uuid];
	
	if ([self.type isEqualToString:@"Task"] && [obj.entity.name isEqualToString:@"Task"]) {
		TaskEditPopoverViewController *viewController = [TaskEditPopoverViewController taskEditPopoverViewController];
		viewController.popover = popover;
		viewController.task = (Task *)obj;
		viewController.shownForDay = nil;
		popover.contentViewController = viewController;
		popover.delegate = viewController;
	}
	else if ([self.type isEqualToString:@"Project"] && [obj.entity.name isEqualToString:@"Project"]) {		
	    ProjectEditPopoverViewController *viewController = [ProjectEditPopoverViewController projectEditPopoverViewController];
		viewController.popover = popover;
		viewController.project = (Project *)obj;
		popover.contentViewController = viewController;
		popover.delegate = viewController;
	}

	if (popover.contentViewController) {
		[popover showRelativeToRect:self.bounds ofView:self preferredEdge:CGRectMaxXEdge];
	}
}

@end
