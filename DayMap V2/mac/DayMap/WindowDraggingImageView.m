//
//  WindowDraggingImageView.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/13/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WindowDraggingImageView.h"

@implementation WindowDraggingImageView {
	NSPoint _startingPoint;
}

// Rather than overriding hitTest, we directly move the containing window.
// This is because there may be other views under this image view and we don't want to click/drag them.
// E.g. the flap over the inbox view.

- (void)mouseDown:(NSEvent *)theEvent
{
	_startingPoint = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint loc = [theEvent locationInWindow];
	NSRect currentLocation = [[self window] convertRectToScreen:NSMakeRect(loc.x, loc.y, 0, 0)];
	NSPoint newOrigin = NSMakePoint(currentLocation.origin.x - _startingPoint.x, currentLocation.origin.y - _startingPoint.y);
	
	[[self window] setFrameOrigin:newOrigin];
}

@end
