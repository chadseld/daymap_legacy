//
//  ProjectMinimizedView.m
//  DayMap
//
//  Created by Chad Seldomridge on 9/27/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "ProjectMinimizedView.h"
#import "NSFont+WS.h"
#import "NSColor+WS.h"
#import "DayMapAppDelegate.h"
#import "Task+Additions.h"

@implementation ProjectMinimizedView {
	NSTimer *_hoverTimer;
}

static NSDictionary *__titleAttributes;
static NSDictionary *titleAttributes() {
    if (!__titleAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSFont dayMapLightFontOfSize:22], NSFontAttributeName,
						   [NSColor dayMapDarkTextColor], NSForegroundColorAttributeName,
						   paragraphStyle, NSParagraphStyleAttributeName,
						   nil];
    }
    return __titleAttributes;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self registerForDraggedTypes:@[DMTaskTableViewDragDataType]];
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
//	[[NSColor redColor] set];
//	NSRectFill(dirtyRect);

	CGFloat rotateDeg = -90;
	NSAffineTransform *rotate = [[NSAffineTransform alloc] init];
	[rotate translateXBy:7 yBy:NSMaxY(self.bounds)-10];
	[rotate rotateByDegrees:rotateDeg];
	[rotate concat];
	
	[self.projectTitle drawAtPoint:NSMakePoint(0, 0) withAttributes:titleAttributes()];
}

- (void)mouseDown:(NSEvent *)theEvent {
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedProject:self.projectUUID];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	[_hoverTimer invalidate];
	_hoverTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(hoverTimerFireMethod:) userInfo:nil repeats:NO];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : self.projectUUID}];
}

@end
