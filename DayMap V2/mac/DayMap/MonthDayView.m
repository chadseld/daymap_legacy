//
//  MonthDayView.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "MonthDayView.h"
#import "NSColor+WS.h"
#import "Task+Additions.h"
#import "NSDate+WS.h"
#import "NSFont+WS.h"
#import "NSMenu+WS.h"
#import "MonthTaskTableCellView.h"

#define ROW_HEIGHT 17
#define TOP_MARGIN 20
#define BOTTOM_MARGIN 3

@interface MonthDayView () <NSMenuDelegate> {
    NSMutableArray *_taskViews;
    BOOL _initializedUI;
	BOOL _inDropOperation;
	BOOL _isFirstDayOfMonth;
	NSTextField *_moreItemsLabel;
	NSPoint _menuMouseDownAtPoint;
	NSPoint _mouseDownAtPoint;
	NSRect _rightClickBorderRect;
}

@property (nonatomic, strong) NSAttributedString *dayString;

@end


@implementation MonthDayView

static NSDictionary *__todayDayAttributes;
static NSDictionary *todayDayAttributes() {
	if (!__todayDayAttributes) {
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		paragraphStyle.alignment = NSCenterTextAlignment;
		paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
		__todayDayAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize] + 1], NSFontAttributeName,
						   [NSColor dayMapLightTextColor], NSForegroundColorAttributeName,
						   paragraphStyle, NSParagraphStyleAttributeName,
						   nil];
	}
	return __todayDayAttributes;
}

static NSDictionary *__dayAttributes;
static NSDictionary *dayAttributes() {
    if (!__dayAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSCenterTextAlignment;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        __dayAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSFont dayMapFontOfSize:[NSFont dayMapBaseFontSize] + 1], NSFontAttributeName,
						   [NSColor dayMapDarkTextColor], NSForegroundColorAttributeName,
						   paragraphStyle, NSParagraphStyleAttributeName,
						   nil];
    }
    return __dayAttributes;
}

static NSDictionary *__firstDayOfMonthAndTodayAttributes;
static NSDictionary *firstDayOfMonthAndTodayAttributes() {
	if (!__firstDayOfMonthAndTodayAttributes) {
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		paragraphStyle.alignment = NSCenterTextAlignment;
		paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
		__firstDayOfMonthAndTodayAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSFont boldDayMapFontOfSize:[NSFont dayMapBaseFontSize] + 1], NSFontAttributeName,
									   [NSColor dayMapLightTextColor], NSForegroundColorAttributeName,
									   paragraphStyle, NSParagraphStyleAttributeName,
									   nil];
	}
	return __firstDayOfMonthAndTodayAttributes;
}

static NSDictionary *__firstDayOfMonthAttributes;
static NSDictionary *firstDayOfMonthAttributes() {
	if (!__firstDayOfMonthAttributes) {
		NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		paragraphStyle.alignment = NSCenterTextAlignment;
		paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
		__firstDayOfMonthAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
						   [NSFont boldDayMapFontOfSize:[NSFont dayMapBaseFontSize] + 1], NSFontAttributeName,
						   [NSColor dayMapDarkTextColor], NSForegroundColorAttributeName,
						   paragraphStyle, NSParagraphStyleAttributeName,
						   nil];
	}
	return __firstDayOfMonthAttributes;
}

static NSDateFormatter *__dayDateFormatter;
static NSDateFormatter *dayDateFormatter() {
	if (!__dayDateFormatter) {
		__dayDateFormatter = [[NSDateFormatter alloc] init];
		[__dayDateFormatter setDateFormat:@"d"];
		__dayDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	}
	return __dayDateFormatter;
}

static NSDateFormatter *__firstDayDateFormatter;
static NSDateFormatter *firstDayDateFormatter() {
	if (!__firstDayDateFormatter) {
		__firstDayDateFormatter = [[NSDateFormatter alloc] init];
		[__firstDayDateFormatter setDateFormat:@"MMMM d"];
		__firstDayDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	}
	return __firstDayDateFormatter;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_taskViews = [[NSMutableArray alloc] init];
		
		[self registerForDraggedTypes:[NSArray arrayWithObject:DMTaskTableViewDragDataType]];
    	
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];

		[self setMenu:[self tasksContextMenu]];
		[[self menu] setDelegate:self];
		
		_moreItemsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 30, ROW_HEIGHT)];
		[_moreItemsLabel setBordered:NO];
		[_moreItemsLabel setBezeled:NO];
		[_moreItemsLabel setSelectable:NO];
		[_moreItemsLabel setEditable:NO];
		[_moreItemsLabel setDrawsBackground:NO];
		[_moreItemsLabel setEnabled:NO];
		[_moreItemsLabel setFont:[NSFont dayMapFontOfSize:[NSFont dayMapSmallListFontSize]]];
		[_moreItemsLabel setTextColor:[NSColor darkGrayColor]];
		[[_moreItemsLabel cell] setLineBreakMode:NSLineBreakByTruncatingTail];
		[self addSubview:_moreItemsLabel];

		_initializedUI = YES;
    }
    return self;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			__dayAttributes = nil;
			_dayString = nil;
			[_moreItemsLabel setFont:[NSFont dayMapFontOfSize:[NSFont dayMapSmallListFontSize]]];
			[self setNeedsDisplay:YES];
			[self resizeSubviewsWithOldSize:self.bounds.size];
		}
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (BOOL)isFlipped {
	return YES;
}

- (NSAttributedString *)dayString {
	if (self.day == nil) {
		return nil;
	}
	
	if (!_dayString) {
		BOOL isToday = [[self.day dateQuantizedToDay] isEqualToDate:[NSDate today]];
		if (_isFirstDayOfMonth) {
			NSString *dateString = [firstDayDateFormatter() stringFromDate:self.day];
			if (dateString == nil) {
				return nil;
			}
			
			if (isToday) {
				_dayString = [[NSAttributedString alloc] initWithString:dateString attributes:firstDayOfMonthAndTodayAttributes()];
			}
			else {
				_dayString = [[NSAttributedString alloc] initWithString:dateString attributes:firstDayOfMonthAttributes()];
			}
		}
		else {
			if (isToday) {
				NSString *dateString = [dayDateFormatter() stringFromDate:self.day];
				if (dateString == nil) {
					return nil;
				}
				
				_dayString = [[NSAttributedString alloc] initWithString:dateString attributes:todayDayAttributes()];
			}
			else {
				NSString *dateString = [dayDateFormatter() stringFromDate:self.day];
				if (dateString == nil) {
					return nil;
				}
				
				_dayString = [[NSAttributedString alloc] initWithString:dateString attributes:dayAttributes()];
			}
		}
	}
	return _dayString;
}

- (void)setDay:(NSDate *)day
{
	_day = day;
	_dayString = nil;
	_isFirstDayOfMonth = [[day beginningOfMonth] isEqualToDate:[day dateQuantizedToDay]];
	[self reloadData];
}

- (void)reloadData
{
    if (!_initializedUI) return;
    
    // Remove all views
    [_taskViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_taskViews removeAllObjects];
    
    NSInteger numRows = [self.dataSource numberOfRowsInMonthDayView:self];
	
    // Add new views
    for (NSInteger row = 0; row < numRows; row++) {
        NSTableCellView *rowView = [self.dataSource monthDayView:self viewForRow:row];
        rowView.autoresizingMask = NSViewWidthSizable;
        [self addSubview:rowView];
        [_taskViews addObject:rowView];
    }
	[self setNeedsDisplay:YES];
	[self resizeSubviewsWithOldSize:self.bounds.size];
}

- (NSRect)rectForRow:(NSInteger)row {
	if (NSNotFound == row) {
		return NSZeroRect;
	}
	return NSIntegralRect(NSMakeRect(_isFirstDayOfMonth ? 4 : 0, TOP_MARGIN + row * ROW_HEIGHT, self.bounds.size.width - (_isFirstDayOfMonth ? 4 : 0), ROW_HEIGHT));
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSInteger numberHidden = 0;
	for (NSInteger row = 0; row < _taskViews.count; row++) {
		NSView *view = _taskViews[row];
		view.frame = [self rectForRow:row];

		BOOL currentRowFits = NSContainsRect(self.bounds, [self rectForRow:row]);
		BOOL willNextRowFit = NSContainsRect(self.bounds, [self rectForRow:row + 1]);
		BOOL shouldHide = !currentRowFits || (!willNextRowFit && row + 1 < _taskViews.count);
		[view setHidden:shouldHide];
		if (shouldHide) {
			numberHidden++;
		}
	}
	
	// The "N more" label
	NSRect viewFrame = [self rectForRow:_taskViews.count - numberHidden];
	viewFrame.origin.x += (_isFirstDayOfMonth ? 7 : 3);
	viewFrame.size.width -= (_isFirstDayOfMonth ? 7 : 3);
	if (!NSContainsRect(self.bounds, viewFrame)) {
		CGFloat x = (_isFirstDayOfMonth ? 7 : 3) + self.dayString.size.width;
		_moreItemsLabel.frame = NSIntegralRect(NSMakeRect(x, 0, self.bounds.size.width - x, TOP_MARGIN));
		[_moreItemsLabel setAlignment:NSRightTextAlignment];
	}
	else {
		_moreItemsLabel.frame = viewFrame;
		[_moreItemsLabel setAlignment:NSLeftTextAlignment];
	}
	
	if (_taskViews.count - numberHidden > 0) {
		_moreItemsLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d more…", @"month view"), numberHidden];
	}
	else {
		if (numberHidden > 1) {
			_moreItemsLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d tasks", @"month view"), numberHidden];
		}
		else {
			_moreItemsLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d task", @"month view"), numberHidden];
		}
	}
	
	[_moreItemsLabel setHidden:numberHidden == 0];
}

- (void)drawRect:(NSRect)dirtyRect {
	// Draw background
	[[NSColor dayMapCalendarBackgroundColor] set];
	NSRectFill(NSInsetRect(self.bounds, 0, 0));

	// Highlight first day of the month
	if (_isFirstDayOfMonth) {
		[[NSColor dayMapCalendarDividerColor] set];
		NSRectFill(NSMakeRect(0, 0, 4, self.bounds.size.height));
	}

	// Geometry to draw day string
	NSSize dayStringSize = self.dayString.size;
	NSRect dayStringDestRect = NSMakeRect(_isFirstDayOfMonth ? 7 : 3, 0, dayStringSize.width, dayStringSize.height);
	
	// Highlight current day
	if ([[self.day dateQuantizedToDay] isEqualToDate:[NSDate today]]) {
		dayStringDestRect.origin.x += dayStringDestRect.size.height / 2;
		
		NSRect stringRect = NSIntegralRectWithOptions(NSInsetRect(dayStringDestRect, ((dayStringDestRect.size.width - dayStringSize.width) / 2) - (dayStringDestRect.size.height / 2), 0), NSAlignAllEdgesOutward);
		stringRect.origin.y += 1;
		stringRect.size.height -= 1;
		if (self.window.isKeyWindow) {
			[[NSColor dayMapCurrentDayHighlightColor] set];
		}
		else {
			[[NSColor colorWithDeviceWhite:[[NSColor dayMapCurrentDayHighlightColor] saturationComponent] alpha:1.0] set];
		}
		[[NSBezierPath bezierPathWithRoundedRect:stringRect xRadius:stringRect.size.height / 2 yRadius:stringRect.size.height / 2] fill];
	}
	
	// Draw Day number in upper right
	[self.dayString drawInRect:dayStringDestRect];
	
	// Drop
	if (_inDropOperation) {
		[[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.85] set];
		if (_isFirstDayOfMonth) {
			NSRectFillUsingOperation(NSMakeRect(4, 0, self.bounds.size.width - 4, self.bounds.size.height), NSCompositeSourceOver);
		}
		else {
			NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
		}
	}
	
	if (!NSIsEmptyRect(_rightClickBorderRect)) {
		[[[NSColor selectedTextBackgroundColor] darkerColor:0.2] set];
		[NSBezierPath setDefaultLineWidth:2];
		[NSBezierPath strokeRect:NSInsetRect(_rightClickBorderRect, 1, 1)];
	}
}

- (void)updateSelection:(NSSet *)selectedTaskIds {
	BOOL monthViewHasFocus = (self.window.firstResponder == self);
    for (NSTableCellView *view in _taskViews) {
		if ([view isKindOfClass:[MonthTaskTableCellView class]]) {
			[((MonthTaskTableCellView *)view) setHighlighted:[selectedTaskIds containsObject:((MonthTaskTableCellView *)view).task.uuid]];
			[((MonthTaskTableCellView *)view) setEmphasized:monthViewHasFocus];
		}
    }
}

- (NSIndexSet *)selectedRowIndexes {
	NSMutableIndexSet *indexes = [NSMutableIndexSet new];
	for (NSInteger i = 0; i < _taskViews.count; i++) {
		NSView *view = [_taskViews objectAtIndex:i];
		if ([view isKindOfClass:[MonthTaskTableCellView class]] && [(MonthTaskTableCellView *)view isHighlighted]) {
			[indexes addIndex:i];
		}
	}
	return indexes;
}

- (NSIndexSet *)clickedRowIndexes {
	NSView *clickedView = [self taskViewHitByMouse:_menuMouseDownAtPoint];
	NSInteger clickedViewIndex = [_taskViews indexOfObject:clickedView];
	NSIndexSet *currentSelection = [self selectedRowIndexes];

	// If clicked view is inside current selection, apply to selection
	if ([currentSelection containsIndex:clickedViewIndex]) {
		return currentSelection;
	}
	else { // If clicked view is outside current selection, apply only to clicked view
		if (clickedViewIndex != NSNotFound) {
			return [NSIndexSet indexSetWithIndex:clickedViewIndex];
		}
	}
	return [NSIndexSet indexSet]; // empty
}

#pragma mark - Actions

- (IBAction)delete:(id)sender {
	[self.delegate monthDayView:self unscheduleRowsWithIndexes:[self selectedRowIndexes]];
}

- (IBAction)edit:(id)sender {
	for (NSTableCellView *view in _taskViews) {
		if ([view isKindOfClass:[MonthTaskTableCellView class]] && ((MonthTaskTableCellView *)view).highlighted) {
			[((MonthTaskTableCellView *)view) showPopover];
			break;
		}
	}
}

- (IBAction)toggleComplete:(id)sender {
	[self.delegate monthDayView:self toggleCompletedRowsWithIndexes:[self selectedRowIndexes]];
}

- (IBAction)showInOpposingView:(id)sender {
	if ([[self selectedRowIndexes] count] <= 0) return;
	[self.delegate monthDayView:self showInOutlineViewRowWithIndex:[[self selectedRowIndexes] lastIndex]];
}

#pragma mark - Mouse

- (NSTableCellView *)taskViewHitByMouse:(NSPoint)mouseLocation {
    for (NSTableCellView *view in _taskViews) {
		if ([view isHidden]) continue;
        if (NSMouseInRect(mouseLocation, view.frame, [view isFlipped])) {
			return view;
        }
    }
    return nil;
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	_menuMouseDownAtPoint = [self convertPoint:event.locationInWindow fromView:nil];
	// TODO - draw a border around clicked rows
	
	NSIndexSet *indexes = [self clickedRowIndexes];
	_rightClickBorderRect = [self rectForRow:[indexes firstIndex]];
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		_rightClickBorderRect = NSUnionRect(_rightClickBorderRect, [self rectForRow:idx]);
	}];
	[self setNeedsDisplay:YES];

	return [super menuForEvent:event];
}

- (void)menuDidClose:(NSMenu *)menu {
	_rightClickBorderRect = NSZeroRect;
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSRect topMarginRect = NSMakeRect(0, 0, self.bounds.size.width, TOP_MARGIN);
	NSPoint mouse = [self convertPoint:theEvent.locationInWindow fromView:nil];
	[self.window makeFirstResponder:self];
	
	_mouseDownAtPoint = NSZeroPoint;
	
	_rightClickBorderRect = NSZeroRect;
	[self setNeedsDisplay:YES];
	
	NSTableCellView *clickedView = [self taskViewHitByMouse:mouse];
	if (clickedView && [clickedView isKindOfClass:[MonthTaskTableCellView class]]) { // Clicked a task view
		for (NSTableCellView *view in _taskViews) {
			if ([view isKindOfClass:[MonthTaskTableCellView class]]) {
				[(MonthTaskTableCellView *)view setHighlighted:view == clickedView];
			}
		}
		NSInteger index = [_taskViews indexOfObject:clickedView];
		[self.delegate monthDayView:self didSelectRowsWithIndexes:[NSIndexSet indexSetWithIndex:index]];
		
		if (theEvent.clickCount == 2) {
			[(MonthTaskTableCellView *)clickedView showPopover];
		}
	}
	else { // Clicked somewhere other than a task view
		// Clicked in top header or the "N more..." button
		BOOL mouseInTopMargin = NSMouseInRect(mouse, topMarginRect, [self isFlipped]);
		BOOL mouseInMoreItemsLabel = NSMouseInRect(mouse, _moreItemsLabel.frame, [self isFlipped]) && ![_moreItemsLabel isHidden];
		if ((mouseInTopMargin || mouseInMoreItemsLabel) && theEvent.clickCount == 2) {
			[self.delegate monthDayView:self showWeek:[self.day beginningOfWeek]];
		}
		else {
			if (!mouseInTopMargin && theEvent.clickCount == 2) {
				[self.delegate monthDayViewAddTask:self];
			}
			else {
				[self.delegate monthDayView:self didSelectRowsWithIndexes:[NSIndexSet indexSet]]; // empty selection
			}
		}
	}
}

#pragma mark -
#pragma mark Drag & Drop

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)becomeFirstResponder {
	BOOL value = [super becomeFirstResponder];
	[self.delegate performSelector:@selector(monthDayViewDidChangeResponderStatus:) withObject:self afterDelay:0];
	return value;
}

- (BOOL)resignFirstResponder {
	BOOL value = [super resignFirstResponder];
	[self.delegate performSelector:@selector(monthDayViewDidChangeResponderStatus:) withObject:self afterDelay:0];
	return value;
}

- (void)mouseDown:(NSEvent *)theEvent {
	_mouseDownAtPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[super mouseDown:theEvent];
}

- (NSImage *)dragImageForRows:(NSIndexSet *)rows {
	return [NSImage imageWithSize:NSMakeSize(self.bounds.size.width, rows.count * ROW_HEIGHT) flipped:YES drawingHandler:^BOOL(NSRect dstRect) {
		__block CGFloat y = 0;
		[rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			NSView *taskView = [_taskViews objectAtIndex:idx];

			NSBitmapImageRep *bir = [taskView bitmapImageRepForCachingDisplayInRect:taskView.bounds];
			[bir setSize:taskView.bounds.size];
			[taskView cacheDisplayInRect:taskView.bounds toBitmapImageRep:bir];
			
			NSImage *image = [[NSImage alloc]initWithSize:taskView.bounds.size];
			[image addRepresentation:bir];
			
			[image drawInRect:NSMakeRect(0, y, image.size.width, image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
			y += ROW_HEIGHT;
		}];
		
		return YES;
	}];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSTableCellView *draggedView = [self taskViewHitByMouse:_mouseDownAtPoint];
    if(!draggedView || ![draggedView isKindOfClass:[MonthTaskTableCellView class]]) return;
	
    NSUInteger hitIndex = [_taskViews indexOfObject:draggedView];
    if(hitIndex == NSNotFound) return;
    NSIndexSet *draggedRows = [NSIndexSet indexSetWithIndex:hitIndex];
    
    NSImage *dragImage = [self dragImageForRows:draggedRows];
	NSRect firstRowRect = [self rectForRow:[draggedRows firstIndex]];
	firstRowRect.origin.y += dragImage.size.height;
    NSPoint imageLocation = firstRowRect.origin;
    
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	[self.delegate monthDayView:self writeRowsWithIndexes:draggedRows toPasteboard:pasteboard];
	
    [self dragImage:dragImage
                 at:imageLocation // The location of the image’s lower-left corner, in the receiver’s coordinate system. It determines the placement of the dragged image under the cursor. When determining the image location you should use the mouse down coordinate, provided in theEvent, rather than the current mouse location.
             offset:NSMakeSize(0,0) // This parameter is ignored.
              event:theEvent
         pasteboard:pasteboard
             source:self
          slideBack:YES];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info {
	if ([info draggingSource] == self) {
		return NSDragOperationNone;
	}
	_inDropOperation = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationMove;
}

- (void)draggingExited:(id <NSDraggingInfo>)info {
	_inDropOperation = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)info {
	NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *droppedTasks = [Task tasksFromPasteboard:pboard fromDate:NULL];
	if (droppedTasks && [droppedTasks count] > 0) return YES;
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info {
	_inDropOperation = NO;
	[self setNeedsDisplay:YES];
	[self resizeSubviewsWithOldSize:self.bounds.size];
	return [self.delegate monthDayView:self acceptDrop:info];
}

#pragma mark - Context Menu

- (NSMenu *)tasksContextMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	
	[menu addItemWithTitle:NSLocalizedString(@"Edit…", @"context menu") action:@selector(contextEdit:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Complete", @"context menu") action:@selector(contextToggleComplete:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Delete", @"context menu") action:@selector(contextDelete:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"New Task…", @"context menu") action:@selector(contextNewTask:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"New Subtask…", @"context menu") action:@selector(contextNewSubtask:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Show", @"context menu") action:@selector(contextShowInOpposingView:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Select All", @"context menu") action:@selector(contextSelectAll:) keyEquivalent:@""];
	
	return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL returnValue = YES;
	
	NSIndexSet *clickedRowIndexes = [self clickedRowIndexes];
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	
	// Main Menu
	//-------
	if (@selector(edit:) == menuItem.action) {
		return selectedRowIndexes.count == 1;
	}
	
	else if (@selector(toggleComplete:) == menuItem.action) {
		NSArray *selectedTasks = [[_taskViews objectsAtIndexes:selectedRowIndexes] valueForKey:@"task"];
		
		BOOL allowed = (selectedTasks.count > 0);
		BOOL anyUncompleted = NO;
		BOOL anyCompleted = NO;
		for (Task *task in selectedTasks) {
			if ([task isCompletedAtDate:self.day partial:nil]) {
				anyCompleted = YES;
			}
			else {
				anyUncompleted = YES;
			}
		}
		if (anyUncompleted && anyCompleted) {
			[menuItem setState:NSMixedState];
		}
		else if (anyCompleted && !anyUncompleted) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}
		
		return allowed;
	}
	
	else if (@selector(showInOpposingView:) == menuItem.action) {
		menuItem.title = NSLocalizedString(@"Show in Outline", @"context menu");
		return selectedRowIndexes.count == 1;
	}
	
	// Context Menus
	//--------
	else if (@selector(contextEdit:) == menuItem.action) {
		BOOL allowed = (clickedRowIndexes.count == 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextToggleComplete:) == menuItem.action) {
		NSArray *clickedTasks = [[_taskViews objectsAtIndexes:clickedRowIndexes] valueForKey:@"task"];

		BOOL allowed = (clickedTasks.count > 0);
		BOOL anyUncompleted = NO;
		BOOL anyCompleted = NO;
		for (Task *task in clickedTasks) {
			if ([task isCompletedAtDate:self.day partial:nil]) {
				anyCompleted = YES;
			}
			else {
				anyUncompleted = YES;
			}
		}
		if (anyUncompleted && anyCompleted) {
			[menuItem setState:NSMixedState];
		}
		else if (anyCompleted && !anyUncompleted) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextDelete:) == menuItem.action) {
		BOOL allowed = (clickedRowIndexes.count > 0);
		menuItem.title = NSLocalizedString(@"Unschedule", @"context menu");
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextNewTask:) == menuItem.action) {
		BOOL allowed = YES;
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextNewSubtask:) == menuItem.action) {
		BOOL allowed = (clickedRowIndexes.count == 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextShowInOpposingView:) == menuItem.action) {
		BOOL allowed = (clickedRowIndexes.count == 1);
		menuItem.title = NSLocalizedString(@"Show in Outline", @"context menu");
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextSelectAll:) == menuItem.action) {
		BOOL allowed = (_taskViews.count > 0);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	[menuItem.menu cleanUpSeparators];
	
	return returnValue;
}

- (void)contextEdit:(id)sender {
	NSView *clickedView = [self taskViewHitByMouse:_menuMouseDownAtPoint];
	NSInteger index = [_taskViews indexOfObject:clickedView];
	
	[self.delegate monthDayView:self didSelectRowsWithIndexes:[NSIndexSet indexSetWithIndex:index]];
	if ([clickedView isKindOfClass:[MonthTaskTableCellView class]]) {
		[(MonthTaskTableCellView *)clickedView showPopover];
	}
}

- (void)contextToggleComplete:(id)sender {
	[self.delegate monthDayView:self toggleCompletedRowsWithIndexes:[self clickedRowIndexes]];
}

- (void)contextDelete:(id)sender {
	[self.delegate monthDayView:self unscheduleRowsWithIndexes:[self clickedRowIndexes]];
}

- (void)contextNewTask:(id)sender {
	[self.delegate monthDayViewAddTask:self];
}

- (void)contextNewSubtask:(id)sender {
	NSView *clickedView = [self taskViewHitByMouse:_menuMouseDownAtPoint];
	NSInteger clickedViewIndex = [_taskViews indexOfObject:clickedView];

	[self.delegate monthDayView:self addSubtaskToTaskAtRow:clickedViewIndex];
}

- (void)contextShowInOpposingView:(id)sender {
	NSView *clickedView = [self taskViewHitByMouse:_menuMouseDownAtPoint];
	NSInteger clickedViewIndex = [_taskViews indexOfObject:clickedView];

	[self.delegate monthDayView:self showInOutlineViewRowWithIndex:clickedViewIndex];
}

- (void)contextSelectAll:(id)sender {
	[self.delegate monthDayView:self didSelectRowsWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _taskViews.count)]];
}

@end
