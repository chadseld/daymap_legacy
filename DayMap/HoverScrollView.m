//
//  HoverScrollView.m
//  DayMap
//
//  Created by Chad Seldomridge on 9/27/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "HoverScrollView.h"
#import "DayMap-Swift.h"

@implementation HoverScrollView {
	NSTimer *_hoverTimer;
}

- (void)awakeFromNib {
	[self registerForDraggedTypes:@[Task.dragDataType]];
}

- (void)drawRect:(NSRect)dirtyRect {
    NSPoint mouse = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
    if (NSMouseInRect(mouse, self.bounds, self.isFlipped) && _hoverTimer != nil) {
        [[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0.1] set];
        NSRectFillUsingOperation(dirtyRect, NSCompositingOperationSourceOver);
            
        CGFloat centerY = floor((NSMaxY(self.bounds) - NSMinY(self.bounds)) / 2);
        CGFloat centerX = floor((NSMaxX(self.bounds) - NSMinX(self.bounds)) / 2);
        CGFloat margin = 4;
        CGFloat minX = margin;
        CGFloat maxX = NSMaxX(self.bounds) - margin;
        CGFloat minY = margin;
        CGFloat maxY = NSMaxY(self.bounds) - margin;
        CGFloat yAmount = self.bounds.size.width;// * 0.8;
        CGFloat xAmount = self.bounds.size.height;// * 0.8;
        
        [[NSColor whiteColor] set];
        [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
        [NSBezierPath setDefaultLineWidth:3];
        if ((NSMinXEdge == self.edge || NSMaxXEdge == self.edge) && self.bounds.size.width < 2*margin + 1) {
            [NSBezierPath setDefaultLineWidth:2];
            minX = margin / 2;
            maxX = NSMaxX(self.bounds) - margin / 2;
        }
        if ((NSMinYEdge == self.edge || NSMaxYEdge == self.edge) && self.bounds.size.height < 2*margin + 1) {
            [NSBezierPath setDefaultLineWidth:2];
            minY = margin / 2;
            maxY = NSMaxY(self.bounds) - margin / 2;
        }

        if (NSMinXEdge == self.edge) {
            [NSBezierPath strokeLineFromPoint:NSMakePoint(minX, centerY) toPoint:NSMakePoint(maxX, centerY + yAmount)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(minX, centerY) toPoint:NSMakePoint(maxX, centerY - yAmount)];
        }
        else if (NSMaxXEdge == self.edge) {
            [NSBezierPath strokeLineFromPoint:NSMakePoint(maxX, centerY) toPoint:NSMakePoint(minX, centerY + yAmount)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(maxX, centerY) toPoint:NSMakePoint(minX, centerY - yAmount)];
        }
        else if (NSMinYEdge == self.edge) {
            [NSBezierPath strokeLineFromPoint:NSMakePoint(centerX, minY) toPoint:NSMakePoint(centerX - xAmount, maxY)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(centerX, minY) toPoint:NSMakePoint(centerX + xAmount, maxY)];
        }
        else if (NSMaxYEdge == self.edge) {
            [NSBezierPath strokeLineFromPoint:NSMakePoint(centerX, maxY) toPoint:NSMakePoint(centerX - xAmount, minY)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(centerX, maxY) toPoint:NSMakePoint(centerX + xAmount, minY)];
        }
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	[_hoverTimer invalidate];
	_hoverTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(hoverTimerFireMethod:) userInfo:nil repeats:NO];
	[self setNeedsDisplay:YES];

	return NSDragOperationEvery;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[_hoverTimer invalidate];
	_hoverTimer = nil;
	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info {
	[_hoverTimer invalidate];
	_hoverTimer = nil;
	[self setNeedsDisplay:YES];
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[_hoverTimer invalidate];
	_hoverTimer = nil;
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	[_hoverTimer invalidate];
	_hoverTimer = nil;
	[self setNeedsDisplay:YES];
}

- (void)hoverTimerFireMethod:(NSTimer *)timer {
	if (self.delegate) {
		_hoverTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(hoverTimerFireMethod:) userInfo:nil repeats:NO];
		[self.delegate hoverScrollViewIsHovering:self];
	}
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
	// We use the standard update timer here and update our scroll view with a new rect.
	// We also adjust the magnitude of scroll depending on the position of the mouse.
	if (self.scrollView) {
		NSPoint point = [self.scrollView.documentView convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
		NSRect rect = NSInsetRect(NSMakeRect(point.x, point.y, 1, 1), -1 * (self.bounds.size.width * 1.5), 0);
		[self.scrollView.documentView scrollRectToVisible:rect];
	}
	
	return NSDragOperationEvery;
}

@end
