//
//  ProjectTableRowView.m
//  DayMap
//
//  Created by Chad Seldomridge on 8/19/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "ProjectTableRowView.h"
#import "NSColor+WS.h"

@implementation ProjectTableRowView

- (BOOL)isOpaque {
	return YES;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	[[NSColor dayMapBackgroundColor] set];
	NSRectFill(dirtyRect);
}

@end
