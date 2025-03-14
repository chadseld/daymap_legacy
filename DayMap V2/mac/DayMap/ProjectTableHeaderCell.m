//
//  ProjectTableHeaderCell.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/31/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectTableHeaderCell.h"
#import "NSColor+WS.h"
#import "MiscUtils.h"
#import "ProjectDisplayAttributes+Additions.h"
#import "NSFont+WS.h"


@implementation ProjectTableHeaderCell {
    NSTextFieldCell *_titleCell;
	NSButtonCell *_minimizeButtonCell;
	NSButtonCell *_menuButtonCell;
	BOOL _mouseDownInMinimizeButton;
	BOOL _mouseDownInMenuButton;
	__weak NSView *_headerView;
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self) {
        _titleCell = [[NSTextFieldCell alloc] initTextCell:@""];
//        [_titleCell setBackgroundColor:[NSColor clearColor]];
        [_titleCell setDrawsBackground:NO];
        [_titleCell setBezeled:NO];
        [_titleCell setEditable:NO];
        [_titleCell setSelectable:NO];
        [_titleCell setAlignment:NSCenterTextAlignment];
        [_titleCell setTextColor:[NSColor whiteColor]];
        [_titleCell setLineBreakMode:NSLineBreakByTruncatingTail];
		[_titleCell setFont:[NSFont dayMapFontOfSize:16.0]];
		
		_minimizeButtonCell = [[NSButtonCell alloc] initTextCell:@""];
		[_minimizeButtonCell setBezeled:NO];
		[_minimizeButtonCell setBordered:NO];
		[_minimizeButtonCell setButtonType:NSMomentaryChangeButton];
		[_minimizeButtonCell setImagePosition:NSImageOnly];
		[_minimizeButtonCell setImageScaling:NSImageScaleNone];
		[_minimizeButtonCell setImage:[NSImage imageNamed:@"unCollapsed"]];

		_menuButtonCell = [[NSButtonCell alloc] initTextCell:@""];
		[_menuButtonCell setBezeled:NO];
		[_menuButtonCell setBordered:NO];
		[_menuButtonCell setButtonType:NSMomentaryChangeButton];
		[_menuButtonCell setImagePosition:NSImageOnly];
		[_menuButtonCell setImageScaling:NSImageScaleNone];
		[_menuButtonCell setImage:[NSImage imageNamed:@"headerMenu"]];
	}
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ProjectTableHeaderCell *cell = (ProjectTableHeaderCell *)[super copyWithZone:zone];
    cell->_titleCell = [_titleCell copy];
    [cell->_titleCell setStringValue:@""];
	cell->_titleString = nil;
    cell->_color = nil;
	cell->_mouseDownInMenuButton = NO;
	cell->_mouseDownInMinimizeButton = NO;
    [cell setColor:[NSColor dayMapActionColor]];
	cell->_minimizeButtonCell = [_minimizeButtonCell copyWithZone:zone];
	cell->_menuButtonCell = [_menuButtonCell copyWithZone:zone];
    return cell;
}

- (void)setTitleString:(NSString *)string
{
	_titleString = string;

//    NSShadow *shadow = [[NSShadow alloc] init];
//    shadow.shadowOffset = NSMakeSize(0, 0.5);
//    shadow.shadowBlurRadius = 1.0;
//    shadow.shadowColor = [NSColor blackColor];
    
	[_titleCell setStringValue:string ? : @""];
//	NSMutableAttributedString *as = [[_titleCell attributedStringValue] mutableCopy];
//	[as addAttribute:NSShadowAttributeName value:shadow range:NSMakeRange(0, [as length])];
//	[_titleCell setAttributedStringValue:as];
}

- (void)setColor:(NSColor *)color
{
    _color = color;
    if(!_color) _color = [NSColor dayMapActionColor];
}

- (void)setMinimized:(BOOL)minimized {
	_minimized = minimized;
	[_minimizeButtonCell setImage:minimized ? [NSImage imageNamed:@"collapsed"] : [NSImage imageNamed:@"unCollapsed"]];
}

- (void)drawArchivedPatternWithColor:(NSColor *)color inRect:(NSRect)cellFrame {
	[NSGraphicsContext saveGraphicsState];

	const CGFloat patternWidth = 10;

	[[[color desaturateColor:0.1] lighterColor:0.1] set];
	NSRectFill(cellFrame);

	[NSBezierPath clipRect:cellFrame];
	[color set];
	[NSBezierPath setDefaultLineWidth:5];
	CGFloat x = 0;
	while (x < NSMaxX(cellFrame)) {
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0)
								  toPoint:NSMakePoint(x + patternWidth, NSMaxY(cellFrame))];
		x += patternWidth;
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // Override super. We don't want to draw the default header bezel
	[[NSColor whiteColor] set];
	NSRectFill(cellFrame);

	if (self.archived) {
		[self drawArchivedPatternWithColor:_color inRect:cellFrame];
	}
	else {
		// Draw Gradient
		[_color set];
		NSRectFill(cellFrame);
	}

    // Draw side bezel
//    [[NSColor colorWithDeviceWhite:0.9 alpha:0.5] set];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(cellFrame)+0.5, 0) toPoint:NSMakePoint(NSMinX(cellFrame)+0.5, cellFrame.size.height)];
    
	// Right Line
	[NSBezierPath setDefaultLineWidth:1];
	[[NSColor dayMapProjectsHeaderDividerColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(cellFrame)-0.5, 0) toPoint:NSMakePoint(NSMaxX(cellFrame)-0.5, cellFrame.size.height)];
	
	// Top Line
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0.5) toPoint:NSMakePoint(NSMaxX(cellFrame), 0.5)];


//    // Bottom line
//    [[NSColor dayMapProjectsHeaderDividerColor] set];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, NSMaxY(cellFrame)-0.5) toPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame)-0.5)];

    // Draw Interior
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect minimizeButtonFrame = [self minimizeButtonFrameForCellFrame:cellFrame];
	NSRect menuButtonFrame = [self menuButtonFrameForCellFrame:cellFrame];

	if (!self.minimized && self.titleString) {
		NSSize textSize = [[_titleCell attributedStringValue] size];
		NSRect destRect = NSInsetRect(cellFrame, 32, (cellFrame.size.height - textSize.height)/2);

		[_titleCell drawInteriorWithFrame:destRect inView:controlView];

		[_menuButtonCell setHighlighted:_mouseDownInMenuButton];
		[_menuButtonCell drawWithFrame:menuButtonFrame inView:controlView];
	}

	if (self.titleString) {
		[_minimizeButtonCell setHighlighted:_mouseDownInMinimizeButton];
		[_minimizeButtonCell drawWithFrame:minimizeButtonFrame inView:controlView];
	}
}

- (void)highlight:(BOOL)highlighted withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawWithFrame:cellFrame inView:controlView];
    if(highlighted) {
		if (self.archived) {
			[self drawArchivedPatternWithColor:[_color darkerColor:0.25] inRect:cellFrame];
		}
		else {
			// Draw Gradient
			[[_color darkerColor:0.25] set];
			NSRectFill(cellFrame);
		}
    }

	// Right Line
	[NSBezierPath setDefaultLineWidth:1];
	[[NSColor dayMapProjectsHeaderDividerColor] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(cellFrame)-0.5, 0) toPoint:NSMakePoint(NSMaxX(cellFrame)-0.5, cellFrame.size.height)];

	// Top Line
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, 0.5) toPoint:NSMakePoint(NSMaxX(cellFrame), 0.5)];

	//	// Bottom line
//    [[NSColor dayMapProjectsHeaderDividerColor] set];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, NSMaxY(cellFrame)-0.5) toPoint:NSMakePoint(NSMaxX(cellFrame), NSMaxY(cellFrame)-0.5)];

	// Draw Interior
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}
//
//- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
//{
//    
//}
//
//- (void)drawSortIndicatorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ascending:(BOOL)ascending priority:(NSInteger)priority
//{
//    
//}

#pragma mark - minimize button handling

- (NSRect)minimizeButtonFrameForCellFrame:(NSRect)cellFrame {
	return NSMakeRect(cellFrame.origin.x + 7, cellFrame.origin.y + 8, 25, cellFrame.size.height - 16);
}

- (NSRect)menuButtonFrameForCellFrame:(NSRect)cellFrame {
	return NSMakeRect(NSMaxX(cellFrame) - 7 -  25, cellFrame.origin.y + 8, 25, cellFrame.size.height - 16);
}

- (BOOL)trackMouse:(NSEvent *)theEvent inMinimizeButtonForCellFrame:(NSRect)cellFrame ofView:(NSView *)controlView {
	NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView: nil];
    
	NSRect frame = [self minimizeButtonFrameForCellFrame:cellFrame];
	if (NSPointInRect(point, frame)) {
		_mouseDownInMinimizeButton = YES;
		[controlView display];
		BOOL returnValue = [self trackMouse:theEvent inRect:frame ofView:controlView untilMouseUp:NO];
		_mouseDownInMinimizeButton = NO;
		[controlView display];
		return returnValue;
	}

	return NO;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inMenuButtonForCellFrame:(NSRect)cellFrame ofView:(NSView *)controlView {
	NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView: nil];

	NSRect frame = [self menuButtonFrameForCellFrame:cellFrame];
	if (NSPointInRect(point, frame)) {
		_mouseDownInMenuButton = YES;
		[controlView display];
		_headerView = controlView;
		return YES;
	}

	return NO;
}

- (void)menuDidClose:(NSMenu *)menu {
	_mouseDownInMenuButton = NO;
	[_headerView setNeedsDisplay:YES];
}

+ (BOOL)prefersTrackingUntilMouseUp {
	return YES;
}

@end
