//
//  ProjectTableHeaderView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/2/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "ProjectTableHeaderView.h"
#import "ProjectTableHeaderCell.h"

@implementation ProjectTableHeaderView

- (void)mouseDown:(NSEvent *)theEvent {
	NSInteger hitColumnNumber = [self columnAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if(hitColumnNumber >= 0) {
		NSTableColumn *column = [[self.tableView tableColumns] objectAtIndex:hitColumnNumber];
		ProjectTableHeaderCell *headerCell = (ProjectTableHeaderCell *)[column headerCell];

		if ([headerCell trackMouse:theEvent inMinimizeButtonForCellFrame:[self headerRectOfColumn:hitColumnNumber] ofView:self]) {
			if ([self.tableView.delegate respondsToSelector:@selector(tableView:didToggleMinimizeForTableColumn:)]) {
				[((id<DMProjectTableViewDelegate>)self.tableView.delegate) tableView:self.tableView didToggleMinimizeForTableColumn:column];
			}
		}
		else if ([headerCell trackMouse:theEvent inMenuButtonForCellFrame:[self headerRectOfColumn:hitColumnNumber] ofView:self]) {
			if ([self.tableView.delegate respondsToSelector:@selector(tableView:didClickHeaderMenuButtonForTableColumn:)]) {
				[((id<DMProjectTableViewDelegate>)self.tableView.delegate) tableView:self.tableView didClickHeaderMenuButtonForTableColumn:column];
			}
		}
		else {
			[super mouseDown:theEvent]; // allow the header to be selected
		}
	}
	else {
		[super mouseDown:theEvent];
	}
}

@end
