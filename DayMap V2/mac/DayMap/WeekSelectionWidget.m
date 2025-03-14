//
//  WeekSelectionWidget.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/7/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WeekSelectionWidget.h"
#import "NSColor+WS.h"
#import "NSDate+WS.h"
#import "NSFont+WS.h"
#import "NSBezierPath+WS.h"

@implementation SelectedWeekLayer

- (void)drawInContext:(CGContextRef)ctx
{	
	// Spiffy magic so that we can draw with the NS APIs
	NSGraphicsContext *nsGraphicsContext;
	nsGraphicsContext = [NSGraphicsContext
						 graphicsContextWithGraphicsPort:ctx
						 flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:nsGraphicsContext];

//	NSDrawThreePartImage(self.bounds, 
//                         [NSImage imageNamed:@"weekSliderLeft"], 
//                         [NSImage imageNamed:@"weekSliderCenter"], 
//                         [NSImage imageNamed:@"weekSliderRight"],
//                         NO, NSCompositeCopy, 1.0, NO);
	
	NSRect trackRect = NSIntegralRect(NSInsetRect(self.bounds, 2.0, 4.0));
	NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
	[track setLineWidth:1];
	[[NSColor dayMapActionColor] set];
	[track fill];
	
	[NSGraphicsContext restoreGraphicsState];
	
	[super drawInContext:ctx];
}

@end


@interface WeekSelectionWidget () < CALayerDelegate>
- (void)_init;
@end

@implementation WeekSelectionWidget {
	SelectedWeekLayer *_selectedBoxLayer;
	CALayer *_weekBackingLayer;
	NSMutableArray *_weekLabelLayers;
	BOOL _animating;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)_init
{
	_week = [[NSDate today] beginningOfWeek]; // just a default value which makes some sense
	_daysDuration = 7;
	_weekLabelLayers = [[NSMutableArray alloc] init];
	
	[self setLayer:[CALayer layer]];
	[self setWantsLayer:YES];
	self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];

	// We use this layer to mask the week layers
	_weekBackingLayer = [CALayer layer];
	[_weekBackingLayer setContentsScale:[[self window] backingScaleFactor]];
	_weekBackingLayer.zPosition = 80;
	[self.layer addSublayer:_weekBackingLayer];
	[_weekBackingLayer addConstraint:[CAConstraint
                          constraintWithAttribute:kCAConstraintMidY
                          relativeTo:@"superlayer"
                          attribute:kCAConstraintMidY]];
	[_weekBackingLayer addConstraint:[CAConstraint
									  constraintWithAttribute:kCAConstraintMidX
									  relativeTo:@"superlayer"
									  attribute:kCAConstraintMidX]];
	[_weekBackingLayer addConstraint:[CAConstraint
									  constraintWithAttribute:kCAConstraintWidth
									  relativeTo:@"superlayer"
									  attribute:kCAConstraintWidth]];
	[_weekBackingLayer addConstraint:[CAConstraint
									  constraintWithAttribute:kCAConstraintHeight
									  relativeTo:@"superlayer"
									  attribute:kCAConstraintHeight]];	
	_weekBackingLayer.masksToBounds = YES;
	_weekBackingLayer.delegate = self;
	
	// We use this layer to draw the selected box. It's not masked to our view bounds.
	_selectedBoxLayer = [SelectedWeekLayer layer];
	[_selectedBoxLayer setContentsScale:[[self window] backingScaleFactor]];
	_selectedBoxLayer.anchorPoint = NSMakePoint(0, 0);
	_selectedBoxLayer.zPosition = 50;
	[self.layer addSublayer:_selectedBoxLayer];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKey:) name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKey:) name:NSWindowDidResignKeyNotification object:nil];
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidChangeKey:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
	[self updateWeekLayers];
	[_weekBackingLayer setNeedsDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			[self updateWeekLayers];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)positionSelectedLayerAround:(CALayer *)layer
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	_selectedBoxLayer.hidden = NO;
//	_selectedBoxLayer.frame = NSIntegralRect(NSMakeRect(NSMinX(layer.frame)-0, ceil((self.bounds.size.height - 21) / 2), layer.frame.size.width+0, 21));
	_selectedBoxLayer.frame = NSIntegralRect(NSMakeRect(NSMinX(layer.frame)-0, 0, layer.frame.size.width+0, self.bounds.size.height));
	[_selectedBoxLayer setNeedsDisplay];
	[CATransaction commit];
}

- (NSString *)stringForWeek:(NSDate *)week
{
	static NSDateFormatter *fmt1 = nil;
	static NSDateFormatter *fmt2 = nil;
	static NSDateFormatter *fmt3 = nil;
	if (nil == fmt1) {
		fmt1 = [[NSDateFormatter alloc] init];
		fmt1.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		[fmt1 setDateFormat:@"MMM d"];
		fmt2 = [[NSDateFormatter alloc] init];
		fmt2.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		[fmt2 setDateFormat:@" - MMM d"];
		fmt3 = [[NSDateFormatter alloc] init];
		fmt3.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		[fmt3 setDateFormat:@" - d"];
	}
	
	if (self.daysDuration > 7) {
		return [[fmt1 stringFromDate:week] stringByAppendingString:[fmt2 stringFromDate:[week dateByAddingDays:self.daysDuration-1]]];
	}
	else {
		return [[fmt1 stringFromDate:week] stringByAppendingString:[fmt3 stringFromDate:[week dateByAddingDays:self.daysDuration-1]]];
	}
}

- (NSUInteger)numberOfWeeksInView
{
	NSUInteger startingSize;
	if (self.daysDuration > 7) {
		startingSize = 102;
	}
	else {
		startingSize = 78;
	}
	return ((NSUInteger)self.bounds.size.width) / startingSize;
}

- (void)updateWeekLayers
{
	if (_animating) return;
	
	[_weekLabelLayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	[_weekLabelLayers removeAllObjects];
	//self.layer.masksToBounds = YES;
	
	NSUInteger numberOfWeeks = [self numberOfWeeksInView];
	NSUInteger curWeekIndex = floor(numberOfWeeks / 2.0 - 0.5);
	CGFloat width = floor((self.bounds.size.width / numberOfWeeks) + 0.5);
	for (NSInteger i=-(NSInteger)numberOfWeeks; i<2*(NSInteger)numberOfWeeks; i++) {
		NSDate *week = [[self.week dateByAddingDays:self.daysDuration*(i - curWeekIndex)] beginningOfWeek];
		CATextLayer *layer = [CATextLayer layer];
		[layer setValue:week forKey:@"WSWeek"];
		layer.string = [self stringForWeek:week];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS]) {
			layer.font = (__bridge_retained CFTypeRef)[NSFont boldDayMapFontOfSize:[NSFont dayMapBaseFontSize] - 1];
		}
		else {
			layer.font = (__bridge_retained CFTypeRef)[NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize] - 1];
		}
		layer.fontSize = [NSFont dayMapBaseFontSize] - 1;
		layer.alignmentMode = kCAAlignmentCenter;
		if ([self.window isKeyWindow]) {
			layer.foregroundColor = [[NSColor dayMapDarkTextColor] CGColor];
		}
		else {
			layer.foregroundColor = [[[NSColor dayMapDarkTextColor] disabledColor] CGColor];
		}
//		layer.foregroundColor = [[NSColor blackColor] CGColor];
//		layer.shadowColor = [[NSColor whiteColor] CGColor];
//		layer.shadowOffset = CGSizeMake(0, -1);
//		layer.shadowRadius = 0;
//		layer.shadowOpacity = 0.7;
		layer.anchorPoint = NSMakePoint(0, 0);
		layer.bounds = NSMakeRect(0, 0, floor(width), self.bounds.size.height);
		layer.position = NSMakePoint(floor(i * width), -3);
		layer.zPosition = 100;
		[layer setContentsScale:[[self window] backingScaleFactor]];
		
		if (i == curWeekIndex) {
			layer.foregroundColor = [[NSColor dayMapLightTextColor] CGColor];
			[self positionSelectedLayerAround:layer];
		}

		[_weekBackingLayer addSublayer:layer];
		[_weekLabelLayers addObject:layer];
	}
}

- (void)viewDidChangeBackingProperties
{
    [super viewDidChangeBackingProperties];
	for (CALayer *layer in _weekLabelLayers) {
		[layer setContentsScale:[[self window] backingScaleFactor]];
	}
	[_weekBackingLayer setContentsScale:[[self window] backingScaleFactor]];
	[_selectedBoxLayer setContentsScale:[[self window] backingScaleFactor]];
}


// This method is for outside callers to set the week of this widget. 
// It does not trigger sending events to the delegate.
// It does not animate (slide), but fades.
- (void)setWeek:(NSDate *)week
{
	if (_week == week || [_week isEqualToDate:week]) return;
    _week = [[week beginningOfWeek] copy];

	[self updateWeekLayers];
}

- (void)setDaysDuration:(NSInteger)daysDuration {
	_daysDuration = daysDuration;
	[self updateWeekLayers];
}

- (void)slideToWeekLayerAndNotifyDelegate:(CALayer *)layer
{
	if ([_delegate respondsToSelector:@selector(setWeek:)]) {
		CGFloat originalPosition = _selectedBoxLayer.position.x;
		[self positionSelectedLayerAround:layer];
		
		[CATransaction begin];
		[CATransaction setDisableActions: YES];
		for (CATextLayer *layer in _weekLabelLayers) {
			((CATextLayer *)layer).foregroundColor = [[NSColor dayMapDarkActionColor] CGColor];
		}
		((CATextLayer *)layer).foregroundColor = [[NSColor dayMapLightTextColor] CGColor];
		[CATransaction commit];
		
		[CATransaction begin];
		_animating = YES;
		[CATransaction setAnimationDuration:0.5];
		[CATransaction setCompletionBlock:^{
			_animating = NO;
			[self updateWeekLayers];
		}];
		
		CGFloat delta = _selectedBoxLayer.position.x - originalPosition;
		for (CALayer *layer in _weekLabelLayers) {
			layer.position = CGPointMake((layer.position.x - delta), layer.position.y);
		}
		_selectedBoxLayer.position = CGPointMake(_selectedBoxLayer.position.x - delta, _selectedBoxLayer.position.y);
		[CATransaction commit];
		
		NSDate *hitWeek = [layer valueForKey:@"WSWeek"];
		self.week = hitWeek; // delegate will probably do this too, but we can't assume
		[(id <WeekSelectionWidgetDelegate>)self.delegate setWeek:hitWeek];
	}
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
	if (layer == _weekBackingLayer) {
		CGContextSaveGState(ctx);
		NSRect trackRect = NSInsetRect(NSIntegralRect(self.bounds), 1, 2.5);
		NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:WS_ROUNDED_CORNER_RADIUS yRadius:WS_ROUNDED_CORNER_RADIUS];
		CGContextAddPath(ctx, [track quartzPath]);
		CGContextSetLineWidth(ctx, 1);
		if ([self.window isKeyWindow]) {
			CGContextSetStrokeColorWithColor(ctx, [NSColor dayMapDarkActionColor].CGColor);
		}
		else {
			CGContextSetStrokeColorWithColor(ctx, [[NSColor dayMapDarkActionColor] disabledColor].CGColor);
		}
		CGContextStrokePath(ctx);
		CGContextRestoreGState(ctx);
	}
}

- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	
	[CATransaction begin];
	[CATransaction setDisableActions: YES];
	for (CALayer *layer in _weekLabelLayers) {
		layer.hidden = (NSMaxX(layer.frame) > newSize.width || NSMinX(layer.frame) < 0);
	}
	_selectedBoxLayer.hidden = NSMaxX(_selectedBoxLayer.frame) > newSize.width;
	[CATransaction commit];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateWeekLayers) object:nil];
	[self performSelector:@selector(updateWeekLayers) withObject:nil afterDelay:0.0];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
	if (_animating) return;
	
	CALayer *hitLayer = nil;
    NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	for (CALayer *layer in _weekLabelLayers) {
		if (NSPointInRect(mouseLocation, layer.frame)) {
			hitLayer = layer;
		}
	}
	
	if (hitLayer) {
		[self slideToWeekLayerAndNotifyDelegate:hitLayer];
	}
}

- (void)swipeWithEvent:(NSEvent *)event
{
	NSDate *hitWeek = nil;
	if ([event deltaX] < 0) { // Right
		hitWeek = [self.week dateByAddingDays:-self.daysDuration];
	}
	else if ([event deltaX] > 0) { // Left
		hitWeek = [self.week dateByAddingDays:self.daysDuration];
	}

	CALayer *hitLayer = nil;
	for (CALayer *layer in _weekLabelLayers) {
		if ([hitWeek isEqualToDate:[layer valueForKey:@"WSWeek"]]) {
			hitLayer = layer;
			break;
		}
	}
		
	if (hitLayer) {
		[self slideToWeekLayerAndNotifyDelegate:hitLayer];
	}
}

//- (void)beginGestureWithEvent:(NSEvent *)event
//{
//	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseBegan inView:nil];
//	for (NSTouch *touch in touches) {
//		NSLog(@"%@", [touch description]);
//	}
//
//	if ([touches count] > 0) {
//	[event trackSwipeEventWithOptions:NSEventSwipeTrackingLockDirection | NSEventSwipeTrackingClampGestureAmount dampenAmountThresholdMin:-1 max:1 usingHandler:^(CGFloat gestureAmount, NSEventPhase phase, BOOL isComplete, BOOL *stop) {
//		NSLog(@"finished");
//	}];
//	}
//}

//- (void)endGestureWithEvent:(NSEvent *)event
//{
//	if ([event type] == NSEventTypeSwipe) {
//		NSLog(@"SWIPE");
//	}
//	NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil];
//	for (NSTouch *touch in touches) {
//		NSLog(@"%@", [touch description]);
//	}
//}


@end
