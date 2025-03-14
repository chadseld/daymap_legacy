//
//  WSModernSegmentedControl.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/17/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSModernSegmentedControl.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"

@implementation WSModernSegmentedCell

static NSDictionary *__highlightedTextAttributes;
static NSDictionary *highlightedTextAttributes() {
    if (!__highlightedTextAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __highlightedTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize]], NSFontAttributeName,
							[NSColor dayMapLightTextColor], NSForegroundColorAttributeName,
							paragraphStyle, NSParagraphStyleAttributeName,
							nil];
    }
    return __highlightedTextAttributes;
}

static NSDictionary *__textAttributes;
static NSDictionary *textAttributes() {
    if (!__textAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize]], NSFontAttributeName,
						   [NSColor dayMapDarkTextColor], NSForegroundColorAttributeName,
						   paragraphStyle, NSParagraphStyleAttributeName,
						   nil];
    }
    return __textAttributes;
}

static NSDictionary *__disabledTextAttributes;
static NSDictionary *disabledTextAttributes() {
    if (!__disabledTextAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __disabledTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize]], NSFontAttributeName,
							[[NSColor dayMapDarkTextColor] disabledColor], NSForegroundColorAttributeName,
							paragraphStyle, NSParagraphStyleAttributeName,
							nil];
    }
    return __disabledTextAttributes;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			__textAttributes = nil;
			__highlightedTextAttributes = nil;
			__disabledTextAttributes = nil;
			[[self controlView] setNeedsDisplay:YES];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)ignoreFrame withView:(NSView *)controlView {
	NSRect controlViewRect = NSInsetRect(controlView.bounds, 1, 0);
	CGFloat segmentWidth = controlViewRect.size.width / self.segmentCount;
	NSRect segmentFrame = NSMakeRect(floor(controlViewRect.origin.x + segment * segmentWidth), controlViewRect.origin.y, floor(segmentWidth), controlViewRect.size.height);
	NSRect pathRect = NSInsetRect(NSIntegralRect(segmentFrame), -0.5, 2.5);
	NSBezierPath *path;
	
	BOOL isFirstSegment = (segment == 0);
	BOOL isLastSegment = (segment == self.segmentCount - 1);

	if (isFirstSegment) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(NSMaxX(pathRect), NSMinY(pathRect))];
		[path lineToPoint:NSMakePoint(NSMinX(pathRect) + WS_ROUNDED_CORNER_RADIUS, NSMinY(pathRect))];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(pathRect) + WS_ROUNDED_CORNER_RADIUS, NSMinY(pathRect) + WS_ROUNDED_CORNER_RADIUS) radius:WS_ROUNDED_CORNER_RADIUS startAngle:270 endAngle:180 clockwise:YES];
		[path lineToPoint:NSMakePoint(NSMinX(pathRect), NSMaxY(pathRect) - WS_ROUNDED_CORNER_RADIUS)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(pathRect) + WS_ROUNDED_CORNER_RADIUS, NSMaxY(pathRect) - WS_ROUNDED_CORNER_RADIUS) radius:WS_ROUNDED_CORNER_RADIUS startAngle:180 endAngle:90 clockwise:YES];
		[path lineToPoint:NSMakePoint(NSMaxX(pathRect), NSMaxY(pathRect))];
		[path closePath];
		[path setLineWidth:1];
	}
	else if (isLastSegment) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(NSMinX(pathRect), NSMinY(pathRect))];
		[path lineToPoint:NSMakePoint(NSMaxX(pathRect) - WS_ROUNDED_CORNER_RADIUS, NSMinY(pathRect))];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(pathRect) - WS_ROUNDED_CORNER_RADIUS, NSMinY(pathRect) + WS_ROUNDED_CORNER_RADIUS) radius:WS_ROUNDED_CORNER_RADIUS startAngle:270 endAngle:0 clockwise:NO];
		[path lineToPoint:NSMakePoint(NSMaxX(pathRect), NSMaxY(pathRect) - WS_ROUNDED_CORNER_RADIUS)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(pathRect) - WS_ROUNDED_CORNER_RADIUS, NSMaxY(pathRect) - WS_ROUNDED_CORNER_RADIUS) radius:WS_ROUNDED_CORNER_RADIUS startAngle:0 endAngle:90 clockwise:NO];
		[path lineToPoint:NSMakePoint(NSMinX(pathRect), NSMaxY(pathRect))];
		[path closePath];
		[path setLineWidth:1];
	}
	else {
		path = [NSBezierPath bezierPathWithRect:pathRect];
		[path setLineWidth:1];
	}
	
	NSRect titleFrame = NSOffsetRect(segmentFrame, 0, 2);
	if ([self controlSize] == NSSmallControlSize) {
		titleFrame = NSOffsetRect(segmentFrame, 0, 1);
	}

	NSColor *strokeColor;
	NSColor *fillColor = [NSColor dayMapActionColor];
	if ([controlView.window isKeyWindow]) {
		strokeColor = [NSColor dayMapDarkActionColor];
//		fillColor = [NSColor dayMapActionColor];
	}
	else {
		strokeColor = [[NSColor dayMapDarkActionColor] disabledColor];
//		fillColor = [[NSColor dayMapActionColor] disabledColor];
	}

	if (self.selectedSegment == segment) {
		[fillColor set];
		[path fill];
		[strokeColor set];
		[path stroke];
		
		[[self labelForSegment:segment] drawInRect:titleFrame withAttributes:highlightedTextAttributes()];
	}
	else {
		[strokeColor set];
		[path stroke];

		if ([controlView.window isKeyWindow]) {
			[[self labelForSegment:segment] drawInRect:titleFrame withAttributes:textAttributes()];
		}
		else {
			[[self labelForSegment:segment] drawInRect:titleFrame withAttributes:disabledTextAttributes()];
		}
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	for (NSInteger segment = 0; segment < self.segmentCount; segment++) {
		if ([self isSelectedForSegment:segment]) continue; // draw selected segment last
		[self drawSegment:segment inFrame:NSZeroRect withView:controlView];
	}
	[self drawSegment:self.selectedSegment inFrame:NSZeroRect withView:controlView];
}

@end


@implementation WSModernSegmentedControl

+ (Class)cellClass
{
    return [WSModernSegmentedCell class];
}

@end
