//
//  ProjectView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/2/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectView.h"
#import "ProjectTaskTableCellView.h"
#import "ProjectTableHeaderView.h"
#import "NSColor+WS.h"
#import "CascadingVerticalOnlyScrollView.h"
#import "DayMapAppDelegate.h"
#import "ProjectEditPopoverViewController.h"
#import "ProjectAddTaskTableCellView.h"
#import "TaskTableRowView.h"
#import "MiscUtils.h"
#import "AbstractTask+Additions.h"
#import "Task+Additions.h"
#import "AbstractTask.h"
#import "NSMenu+WS.h"
#import "NSDate+WS.h"
#import "ProjectMinimizedView.h"
#import "DayMap.h"

#define TASK_HEIGHT 25
#define NOTES_HEIGHT 16

@interface ProjectView ()
//- (void)addTaskView;
//- (void)editTask:(Task *)task;
//- (void)removeTaskView;
//- (void)layoutTaskViews;
@end

@implementation ProjectView {
	NSOutlineView *_tasksOutlineView;
	NSScrollView *_tasksScrollView;
	ProjectMinimizedView *_minimizedView;
	CGFloat _prevWidth;
	BOOL _amUpdatingSelection;
}

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor dayMapProjectsDividerColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(self.bounds)-0.5, NSMinY(self.bounds))
							  toPoint:NSMakePoint(NSMaxX(self.bounds)-0.5, NSMaxY(self.bounds))];
}

- (id)initWithFrame:(NSRect)frame
{
    if (NSEqualRects(NSZeroRect, frame)) {
        frame = NSMakeRect(0, 0, 100, 300); // need some default size to work with. Autolayout will handle resizing later on.
    }

    self = [super initWithFrame:frame];
    if (self) {
        [self setAutoresizesSubviews:YES];

//		_tasksTreeController = [[NSTreeController alloc] init];
//		[_tasksTreeController bind:@"content" toObject:self withKeyPath:@"project.children" options:nil];
//		[_tasksTreeController setChildrenKeyPath:@"children"];
		
		_minimizedView = [[ProjectMinimizedView alloc] initWithFrame:NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height)];
		[_minimizedView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_minimizedView setHidden:YES];
		[self addSubview:_minimizedView];
		
		// Create Outline View		
        NSRect outlineViewRect = NSMakeRect(0, 0, self.bounds.size.width-1, self.bounds.size.height);
		_tasksOutlineView = [[NSOutlineView alloc] initWithFrame:outlineViewRect];
        [_tasksOutlineView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapBackgroundColor]];
		[_tasksOutlineView setIntercellSpacing:NSMakeSize(2, 0)];
        [_tasksOutlineView setVerticalMotionCanBeginDrag:YES];
        [_tasksOutlineView registerForDraggedTypes:[NSArray arrayWithObject:DMTaskTableViewDragDataType]];
		[_tasksOutlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
        [_tasksOutlineView setFocusRingType:NSFocusRingTypeNone];
        [_tasksOutlineView setHeaderView:nil];
		[_tasksOutlineView setAutosaveExpandedItems:NO];
		[_tasksOutlineView setAutoresizesOutlineColumn:NO];
		[_tasksOutlineView setIndentationPerLevel:15];
		[_tasksOutlineView setIndentationMarkerFollowsCell:YES];
		[_tasksOutlineView setAllowsMultipleSelection:YES];
		[_tasksOutlineView setMenu:[self contextMenu]];
		[_tasksOutlineView setTarget:self];
		[_tasksOutlineView setAction:@selector(tableViewAction:)];
		_tasksOutlineView.delegate = self;
		_tasksOutlineView.dataSource = self;
		NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"task"];
		[_tasksOutlineView addTableColumn:column];
		[_tasksOutlineView setOutlineTableColumn:column];
                
		// Tasks Scroll View
        _tasksScrollView = [[CascadingVerticalOnlyScrollView alloc] initWithFrame:outlineViewRect];
        [_tasksScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_tasksScrollView setHasVerticalScroller:YES];
        [_tasksScrollView setHasHorizontalScroller:NO];
        [_tasksScrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
        [_tasksScrollView setBorderType:NSNoBorder];
        [_tasksScrollView setDrawsBackground:YES];
        [_tasksScrollView setAutohidesScrollers:YES];
		_tasksScrollView.documentView = _tasksOutlineView;
        [self addSubview:_tasksScrollView];
        
        [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];

		[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"completedDateFilter" options:0 context:(__bridge void*)self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(childrenDidChangeForParentNotification:) name:DMChildrenDidChangeForParentNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expandChildrenOfTaskNotification:) name:DMExpandChildrenOfTaskNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeTaskVisibleNotification:) name:DMMakeTaskVisibleNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rowSizeChangedNotification:) name:DMResizeRowForTaskNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeManagedObjectContextNotification:) name:DMWillChangeManagedObjectContext object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeManagedObjectContextNotification:) name:DMDidChangeManagedObjectContext object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKeyNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKeyNotification:) name:NSWindowDidResignKeyNotification object:nil];
		
		[[NSUserDefaults standardUserDefaults] addObserver:self
												forKeyPath:PREF_SHOW_NOTES_IN_OUTLINE options:NSKeyValueObservingOptionNew
												   context:NULL];

    }
    
    return self;
}

- (void)dealloc 
{
	_tasksOutlineView.delegate = nil;
	_tasksOutlineView.dataSource = nil;
	_tasksOutlineView = nil;

	// TODO - why does this get called at launch??
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"completedDateFilter" context:(__bridge void*)self];
	[self.project removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_NOTES_IN_OUTLINE context:NULL];
}

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification {
	_tasksOutlineView.delegate = nil;
	_tasksOutlineView.dataSource = nil;
}

- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	_tasksOutlineView.delegate = self;
	_tasksOutlineView.dataSource = self;
}

- (void)updateSelection
{
	_amUpdatingSelection = YES;
	BOOL selected = NO;
	[_tasksOutlineView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    for (NSString *taskUUID in [(DayMapAppDelegate *)[NSApp delegate] selectedTasks]) {
        Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
//        Project *root = [task rootProject];
//        if (![[root uuid] isEqual:self.project.uuid]) {
//            [_tasksOutlineView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO]; // clear selection
//        }
//        else {
            NSInteger rowIndex = [_tasksOutlineView rowForItem:task];
            if (rowIndex != -1) {
                [_tasksOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:YES];
                [_tasksOutlineView scrollRowToVisible:rowIndex];
				selected = YES;
            }
//        }
    }
	if (!selected) {
		[_tasksOutlineView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO]; // clear selection
	}
	_amUpdatingSelection = NO;
}

- (void)updateAndReloadOutline:(void(^)(void))completion
{
	if (nil == self.project) return;
	
	// Update filtered tasks and reload table view
	dispatch_async(dispatch_get_main_queue(), ^{
		if (!DMCurrentManagedObjectContext) {
			if (completion) {
				completion();
			}
			return;
		}

		[_tasksOutlineView reloadData];
		[_tasksOutlineView setAutosaveExpandedItems:YES];
		[_tasksOutlineView setAutosaveName:_project.uuid];
		[self updateSelection];
		if (completion) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion();
			});
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString *taskToEdit = ((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit;
			if (taskToEdit) [self editTask:(Task *)[DMCurrentManagedObjectContext objectWithUUID:taskToEdit]];
		});
	});
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"completedDateFilter"]) {
			[self updateAndReloadOutline:nil];
        }
        else if ([keyPath isEqualToString:@"selectedTasks"]) {
			[self updateSelection];
        }
		else if ([keyPath isEqualToString:@"name"]) {
			_minimizedView.projectTitle = self.project.name;
		}
    }
	else if ([keyPath isEqualToString:PREF_SHOW_NOTES_IN_OUTLINE]) {
		[self updateAndReloadOutline:nil];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)childrenDidChangeForParentNotification:(NSNotification *)notification
{
    AbstractTask *task = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:[notification object]];
    Project *root = [(AbstractTask *)task rootProject];
        
    // If this project view is displaying this changed object, update.
    if ([[root uuid] isEqual:self.project.uuid]) {
        [self updateAndReloadOutline:nil];
        //NSLog(@"childrenDidChangeForParentNotification parent = %@ ", [[notification object] description]);
    }
}

- (void)expandChildrenOfTaskNotification:(NSNotification *)notification
{
	AbstractTask *task = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:[notification object]];
	[self expandChildrenOfTask:(Task *)task];
}

- (void)makeTaskVisibleNotification:(NSNotification *)notification
{
	NSString *taskUUID = [[notification userInfo] objectForKey:@"uuid"];
	
	Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
	Project *root = [task rootProject];
	if (![[root uuid] isEqual:self.project.uuid]) {
		return;
	}
	[self expandParentsOfTask:task];
	NSInteger rowIndex = [_tasksOutlineView rowForItem:task];
	if (rowIndex != -1) {
		[_tasksOutlineView scrollRowToVisible:rowIndex];
	}
	[_tasksOutlineView.window makeFirstResponder:_tasksOutlineView];
}

- (void)rowSizeChangedNotification:(NSNotification *)notification {
	
	NSString *taskUUID = [notification object];
	Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
	Project *root = [task rootProject];
	if (![[root uuid] isEqual:self.project.uuid]) {
		return;
	}

	NSInteger rowIndex = [_tasksOutlineView rowForItem:task];
	if (rowIndex != -1) {
		[_tasksOutlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:rowIndex]];
	}
}

- (void)expandChildrenOfTask:(Task *)task {
	Project *root = [task rootProject];
    
    // If this project view is displaying this changed object, update.
    if ([[root uuid] isEqual:self.project.uuid]) {
		[_tasksOutlineView beginUpdates];
		[self updateAndReloadOutline:^{
			[_tasksOutlineView expandItem:task];
			[_tasksOutlineView endUpdates];
			[_tasksOutlineView setNeedsDisplay:YES];
		}];
	}
}

- (void)expandParentsOfTask:(Task *)task
{
	NSMutableArray *toExpand = [NSMutableArray new];
	AbstractTask *parent = nil;
	AbstractTask *current = task;
	while ([[[(parent = current.parent) entity] name] isEqualToString:@"Task"]) {
		[toExpand insertObject:parent atIndex:0];
		current = parent;
	}
	for (Task *t in toExpand) {
		[_tasksOutlineView expandItem:t];
	}
}

//- (void)updateTrackingAreas
////- (void)adjustTrackingRect
//{
//   // DLog(@"updateTrackingAreas");
//	
//	if (!NSEqualRects(_trackingArea.rect, self.bounds)) {
//		[self removeTrackingArea:_trackingArea];
//		_trackingArea = nil;
//    
//		if (!NSEqualRects(NSZeroRect, [self visibleRect])) {
//			_trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingEnabledDuringMouseDrag owner:self userInfo:nil];
//			[self addTrackingArea:_trackingArea];
//		}
//	}
//}

//- (void)mouseExited:(NSEvent *)theEvent
//{
////	NSBeep();
////	[_tasksTableView setNeedsDisplay:YES];
//    if (!NSEqualRects(NSZeroRect, [self visibleRect])) {
//        NSScrollView *projectsScrollView = [self enclosingScrollView];
//        [projectsScrollView setNeedsDisplayInRect:[projectsScrollView visibleRect]];
//    }
//}
//
//- (void)mouseMoved:(NSEvent *)theEvent
//{
//    static NSView /*__weak*/ *__previousHoveredView = nil;
//
//    NSPoint mouseLocation = [theEvent locationInWindow];//[self convertPointFromBase:[theEvent mouseLocation]];//[self convertPointFromBase:[[self window] mouseLocationOutsideOfEventStream]];
//
//    NSView *hitView = nil;
//    for (NSInteger row = 0; row < [_tasksTableView numberOfRows]; row++) {
//		NSView *view = [_tasksTableView viewAtColumn:0 row:row makeIfNecessary:NO];
//		if (!view) continue;
//		
//        if (NSPointInRect(mouseLocation, [view convertRectToBase:view.bounds])) {
//            hitView = view;
//            break;
//        }
//    }
//    if (hitView != __previousHoveredView) {
//        [hitView setNeedsDisplay:YES];
//        [__previousHoveredView setNeedsDisplay:YES];
//        __previousHoveredView = hitView;
//		
//		if (nil == __previousHoveredView) {
//			NSScrollView *projectsScrollView = [self enclosingScrollView];
//			[projectsScrollView setNeedsDisplayInRect:[projectsScrollView visibleRect]];
//		}
//    }
//}

//- (void)drawRect:(NSRect)dirtyRect
//{    
//    [super drawRect:dirtyRect];
//    
//    // Draw side bezel
//    [[NSColor colorWithDeviceWhite:0.3 alpha:1] set];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint(self.bounds.size.width-0.5, 0) toPoint:NSMakePoint(self.bounds.size.width-0.5, self.bounds.size.height)];
//}

- (void)setIsInbox:(BOOL)isInbox {
	_isInbox = isInbox;
	if (isInbox) {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapInboxBackgroundColor]];
	}
	else {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapBackgroundColor]];
	}
}

- (void)windowDidBecomeKeyNotification:(NSNotification *)notification {
	if (self.isInbox) {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapInboxBackgroundColor]];
	}
	else {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapBackgroundColor]];
	}
}

- (void)windowDidResignKeyNotification:(NSNotification *)notification {
	if (self.isInbox) {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapInboxBackgroundColorInactive]];
	}
	else {
		[_tasksOutlineView setBackgroundColor:[NSColor dayMapBackgroundColor]];
	}
}

- (void)setProject:(Project *)project
{
    if (_project != project) {
		[self.project removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
		[_tasksOutlineView setAutosaveExpandedItems:NO];
		
        _project = project;
		
		_minimizedView.projectTitle = _project.name;
		_minimizedView.projectUUID = _project.uuid;
		[self.project addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
		[self updateAndReloadOutline:nil];
    }
}

- (void)addTask {
    Task *task = [Task task];
	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;
	
	NSMutableSet *tasks = [self.project mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
}

- (void)editTask:(Task *)task
{
	if (![self superview]) return;
	
	NSInteger rowIndex = [_tasksOutlineView rowForItem:task];
	if (rowIndex != -1) {
		((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = nil;
		ProjectTaskTableCellView *rowView = [_tasksOutlineView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
		[_tasksOutlineView scrollRowToVisible:rowIndex];
		[_tasksOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
		[_tasksOutlineView.window makeFirstResponder:_tasksOutlineView];
		[rowView showPopover];
	}
}

- (IBAction)edit:(id)sender {
	if ([_tasksOutlineView selectedRow] == -1) return;
	
	[self editTask:[_tasksOutlineView itemAtRow:[_tasksOutlineView selectedRow]]];
}

- (IBAction)toggleComplete:(id)sender {
	__block NSMutableArray *selectedTasks = [NSMutableArray array];
	[[_tasksOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[selectedTasks addObject:[_tasksOutlineView itemAtRow:idx]];
	}];
	[Task toggleCompleted:selectedTasks atDate:nil];
}

- (IBAction)showInOpposingView:(id)sender {
	if ([_tasksOutlineView selectedRow] == -1) return;
		
	Task *task = [_tasksOutlineView itemAtRow:[_tasksOutlineView selectedRow]];
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:task.uuid]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleInCalendarNotification object:nil userInfo:@{@"uuid" : [task valueForKey:@"uuid"]}];
}

- (void)setMinimized:(BOOL)minimized {
	_minimized = minimized;

	if (minimized) {
		_tasksScrollView.documentView = nil; // so that we don't get autolayout errors from squishing content
	}
	else {
		_tasksScrollView.documentView = _tasksOutlineView;
	}
	
	[_tasksScrollView setHidden:minimized];
	[_minimizedView setHidden:!minimized];
}

- (BOOL)canExpandAll {
	for (NSInteger i = 0; i < [_tasksOutlineView numberOfRows]; i++) {
		id item = [_tasksOutlineView itemAtRow:i];
		if ([_tasksOutlineView isExpandable:item] && ![_tasksOutlineView isItemExpanded:item]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)canCollapseAll {
	for (NSInteger i = 0; i < [_tasksOutlineView numberOfRows]; i++) {
		id item = [_tasksOutlineView itemAtRow:i];
		if ([_tasksOutlineView isExpandable:item] && [_tasksOutlineView isItemExpanded:item]) {
			return YES;
		}
	}
	return NO;
}

- (void)expandAll {
	for (NSInteger i = 0; i < [self outlineView:_tasksOutlineView numberOfChildrenOfItem:nil]; i++) {
		id item = [self outlineView:_tasksOutlineView child:i ofItem:nil];
		if ([_tasksOutlineView isExpandable:item]) {
			[_tasksOutlineView expandItem:item expandChildren:YES];
		}
	}
}

- (void)collapseAll {
	for (NSInteger i = 0; i < [self outlineView:_tasksOutlineView numberOfChildrenOfItem:nil]; i++) {
		id item = [self outlineView:_tasksOutlineView child:i ofItem:nil];
		if ([_tasksOutlineView isExpandable:item]) {
			[_tasksOutlineView collapseItem:item collapseChildren:YES];
		}
	}
}

#pragma mark -
#pragma mark Table View

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
	TaskTableRowView *result = [outlineView makeViewWithIdentifier:@"taskRow" owner:self];
	
	// There is no existing cell to reuse so we will create a new one
	if (result == nil) {
		
		// create the new view with a frame of the {0,0} with the width of the table
		// note that the height of the frame is not really relevant, the row-height will modify the height
		// the new text field is then returned as an autoreleased object
		//		NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"TaskTableRowView" bundle:nil];
		//		result = (TaskTableRowView *)throwAwayViewController.view;
		result = [[TaskTableRowView alloc] initWithFrame:NSMakeRect(0, 0, _tasksOutlineView.bounds.size.width, TASK_HEIGHT)];
		
		// the identifier of the view instance is set to task. This
		// allows it to be re-used
		result.identifier = @"taskRow";
	}
	
	// Configure the view
	
	
	// return the result.
	return result;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if (_amUpdatingSelection) return;
	
	__block NSMutableSet *selectedTasks = [NSMutableSet set];
	[[_tasksOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[selectedTasks addObject:[[_tasksOutlineView itemAtRow:idx] valueForKey:@"uuid"]];
	}];
    
	if (selectedTasks.count == 0) return;
	
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self]; // turn off observing, so that we don't clear our own selection
    [(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:selectedTasks];
    [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [item isEqualToString:@"WSNewItemRow"]) {
		return NO;
	}
	if (nil == item) { // root
		return NO;
	}
	if ([[[item entity] name] isEqualToString:@"Task"]) {
		NSUInteger num = ((Task *)item).sortedFilteredChildren.count;
		return num > 0;
	}
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [item isEqualToString:@"WSNewItemRow"]) {
		return NO;
	}
	return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (nil == item) { // root
		if (index < self.project.sortedFilteredChildren.count) return [self.project.sortedFilteredChildren objectAtIndex:index];
		else return @"WSNewItemRow";
	}
	else if ([[[item entity] name] isEqualToString:@"Task"]) {
		return [((Task *)item).sortedFilteredChildren objectAtIndex:index];
	}
	else {
		return @"";
	}
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (nil == item) {
		return self.project.sortedFilteredChildren.count + 1;
	}
	else if ([[[item entity] name] isEqualToString:@"Task"]) {
		return ((Task *)item).sortedFilteredChildren.count;
	}
	else {
		return 1;
	}
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [item isEqualToString:@"WSNewItemRow"]) {
		ProjectAddTaskTableCellView *result = [outlineView makeViewWithIdentifier:@"addtask" owner:self];
		
		// There is no existing cell to reuse so we will create a new one
		if (result == nil) {
			
			// create the new view with a frame of the {0,0} with the width of the table
			// note that the height of the frame is not really relevant, the row-height will modify the height
			// the new text field is then returned as an autoreleased object
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"ProjectAddTaskTableCellView" bundle:nil];
			result = (ProjectAddTaskTableCellView *)throwAwayViewController.view;
			
			// the identifier of the view instance is set to task. This
			// allows it to be re-used
			result.identifier = @"addtask";
		}
		
		result.projectView = self;
		
		return result;
	}
	else {
		// get an existing cell with the task identifier if it exists
		ProjectTaskTableCellView *result = [outlineView makeViewWithIdentifier:@"task" owner:self];
		
		// There is no existing cell to reuse so we will create a new one
		if (result == nil) {
			
			// create the new view with a frame of the {0,0} with the width of the table
			// note that the height of the frame is not really relevant, the row-height will modify the height
			// the new text field is then returned as an autoreleased object
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"ProjectTaskTableCellView" bundle:nil];
			result = (ProjectTaskTableCellView *)throwAwayViewController.view;
			
			// the identifier of the view instance is set to task. This
			// allows it to be re-used
			result.identifier = @"task";
		}
		
		// result is now guaranteed to be valid, either as a re-used cell
		// or as a new cell, so set the value of the cell to the value at row
		result.day = nil;
		result.task = item;

		// return the result.
		return result;
	}
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([item isKindOfClass:[Task class]]) {
		Task *task = (Task *)item;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_NOTES_IN_OUTLINE] && task.attributedDetails != nil) {
			return TASK_HEIGHT + NOTES_HEIGHT;
		}
		else {
			return TASK_HEIGHT;
		}
	}
    return TASK_HEIGHT;
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
	if ([object hasSuffix:@"WSNewItemRow"]) {
		return @"WSNewItemRow";
	}
	else {
		NSString *taskUUID = (NSString *)object;
		if (nil == taskUUID) return nil;
        Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
		return task;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
	if ([item isKindOfClass:[NSString class]] && [item isEqualToString:@"WSNewItemRow"]) {
		return [self.project.uuid stringByAppendingString:@"WSNewItemRow"];
	}
	else {
		return [item valueForKey:@"uuid"];
	}
}

- (void)tableViewAction:(id)sender
{
	if ([[NSApp currentEvent] type] == NSLeftMouseUp && [NSApp currentEvent].clickCount == 2 && [_tasksOutlineView clickedColumn] >=0 && [_tasksOutlineView clickedRow] >=0) {
		TaskTableCellView *cellView = [_tasksOutlineView viewAtColumn:[_tasksOutlineView clickedColumn] row:[_tasksOutlineView clickedRow] makeIfNecessary:NO];
		if ([cellView isKindOfClass:[TaskTableCellView class]]) {
			[cellView showPopover];
		}
	}
	else if ([[NSApp currentEvent] type] == NSLeftMouseUp && [NSApp currentEvent].clickCount == 2) {
		[self addTask];
	}
	else {
		// This action is called whenever a mouse is clicked in the table view. Either a row is clicked, or the area under the row is clicked. 
		// If the area under the row is clicked, we generate an (possibly additional) selectionDidChange notification. This is because the selection 
		// may be in another table view in the app and we still need to clear it.
		if ([[_tasksOutlineView selectedRowIndexes] count] == 0) { // if empty selection
			[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:nil];
		}
	}
}

#pragma mark -
#pragma mark Drag & Drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
	// Only drag tasks, no the '+' row
	NSMutableArray *tasks = [NSMutableArray array];
	for (id item in items) {
		if ([item isKindOfClass:[NSManagedObject class]] && [[[((NSManagedObject *)item) entity] name] isEqualToString:@"Task"]) {
			[tasks addObject:item];
		}		
	}
	
	// If any ancestor of a task is selected, ignore it. It will be picked up automatically by moving the parent.
	NSMutableSet *tasksSet = [NSMutableSet setWithArray:tasks];
	for (Task *task in tasksSet) {
		NSSet *parentsSet = [NSSet setWithArray:[task breadcrumbs]];
		if (parentsSet.count <= 1) { // the first crumb is the project
			continue;
		}
		if ([tasksSet intersectsSet:parentsSet]) {
			[tasks removeObject:task];
		}
	}

    // Copy the tasks to the pasteboard.
	if(tasks.count > 0) {
		[Task placeTasks:tasks onPasteboard:pasteboard fromDate:nil];
		return YES;
	}

	return NO;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    //NSLog(@"item = %@, index = %ld.....project.children.count = %ld", [item description], index, self.project.sortedFilteredChildren.count);

    // Dragging on or below the '+' add row, we reposition the drop
    if (([item isKindOfClass:[NSString class]] && [item isEqualToString:@"WSNewItemRow"]) ||
        (nil == item && index > self.project.sortedFilteredChildren.count)) { // don't drop on or below the new item row
        [outlineView setDropItem:nil dropChildIndex:self.project.sortedFilteredChildren.count];
        return NSDragOperationMove;
    }

    // Don't allow item to be dropped inside itself
    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *draggedTasks = [Task tasksFromPasteboard:pboard fromDate:NULL];
	id task = item;
	id nextUp = nil;
	while ([[[task entity] name] isEqualToString:@"Task"] && 
		   ((nextUp = [task valueForKey:@"parent"]) != nil)) {
		
		if ([draggedTasks containsObject:task]) {
			return NSDragOperationNone;
		}
		task = nextUp;
	}

	if (WSIsOptionKeyPressed()) {
		return NSDragOperationCopy;
	}
	else {
		return NSDragOperationMove;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
	NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *droppedTasks = [Task tasksFromPasteboard:pboard fromDate:NULL];
	
	//NSLog(@"acceptDrop item = %@, index = %ld.....project.children.count = %ld", [item description], index, self.project.sortedFilteredChildren.count);

	id parent;
	NSSet *toSet; // the actual set stored back into core data
	NSArray *sortedProjectTasks, *sortedFilteredProjectTasks;
	if (nil == item) parent = self.project;
	else parent = item;

	toSet = [parent valueForKey:@"children"];
	sortedProjectTasks = [toSet sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	sortedFilteredProjectTasks = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(toSet, [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], nil, SORT_BY_SORTINDEX);

	// We are going to perform these sort/drop operations on the regular, non-completed-filtered, task sets
	// row is possibly incorrect. There may be hidden completed tasks in the list in an index < row.
	// find the item at row in the filtered array, and find the same item in non-filtered array
	// The item index in the non-filtered array should be used as row
	if (index < 0 || index >= [sortedFilteredProjectTasks count]) {
		index = toSet.count;
	}
	else {
		Task *hitTask = [sortedFilteredProjectTasks objectAtIndex:index];
		index = [sortedProjectTasks indexOfObject:hitTask];
	}
	
	NSArray *movedTaskUUIDs = WSMoveTasksToParent(droppedTasks, parent, index, WSIsOptionKeyPressed());
	
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithArray:movedTaskUUIDs]];

	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:[parent valueForKey:@"uuid"] userInfo:nil];
	
    // Move the specified row to its new location...
    return YES;
}

#pragma mark - Keyboard

- (void)keyDown:(NSEvent *)event {
	// ASCII characters lookup
	//const int RETURN_KEY = 0x000D;
	//const int ENTER_KEY = 0x0003;
	const int SPACE_KEY = 0x0020;
	
	unichar key = 0;
	NSString *characters = nil;
	BOOL isARepeat = NO;
	if([event type] == NSKeyDown) {
		characters = [event charactersIgnoringModifiers];
		if([characters length] > 0) key = [characters characterAtIndex:0];
		isARepeat = [event isARepeat];
	}
	if (isARepeat) {
		return;
	}

	BOOL isCommandKeyDown = [event modifierFlags] & NSCommandKeyMask ? YES : NO;
	BOOL isOptionKeyDown = [event modifierFlags] & NSAlternateKeyMask ? YES : NO;
	BOOL isControlKeyDown = [event modifierFlags] & NSControlKeyMask ? YES : NO;

	if (isCommandKeyDown || isOptionKeyDown || isControlKeyDown) {
		return;
	}
	
	/*if(RETURN_KEY == key ||
	   ENTER_KEY == key) {
		[self editTask:[_tasksOutlineView itemAtRow:[_tasksOutlineView selectedRow]]];
	}
	else */if(SPACE_KEY == key) {
		NSMutableArray *selectedTasks = [NSMutableArray new];
		[[_tasksOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			Task *task = [_tasksOutlineView itemAtRow:idx];
			if (!task) return;
			[selectedTasks addObject:task];
		}];
		
		[Task toggleCompleted:selectedTasks atDate:nil];
	}
	else {
		[super keyDown:event];
	}
}

#pragma mark - Context Menu

- (NSMenu *)contextMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	
	[menu addItemWithTitle:NSLocalizedString(@"Edit…", @"context menu") action:@selector(contextEdit:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Complete", @"context menu") action:@selector(contextToggleComplete:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Delete", @"context menu") action:@selector(contextDelete:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"Schedule for Today", @"context menu") action:@selector(contextScheduleForToday:) keyEquivalent:@""];

	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItem:[self moveToMenuItemForTask:nil]];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"New Task…", @"context menu") action:@selector(contextNewTask:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"New Subtask…", @"context menu") action:@selector(contextNewSubtask:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Show", @"context menu") action:@selector(contextShowInOpposingView:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Select All", @"context menu") action:@selector(contextSelectAll:) keyEquivalent:@""];
	
	return menu;
}

- (NSMenuItem *)moveToMenuItemForTask:(AbstractTask *)parentTask {
	if (parentTask) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:parentTask.name action:@selector(contextMoveTo:) keyEquivalent:@""];
		menuItem.representedObject = parentTask.uuid;

		if (parentTask.sortedFilteredChildren.count > 0) {
			NSMenu *submenu = [[NSMenu alloc] init];
			submenu.delegate = self;
			[menuItem setSubmenu:submenu];
		}
		
		return menuItem;
	}
	else { // root
		NSMenuItem *moveToItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Move To", @"context menu") action:nil keyEquivalent:@""];

		NSMenu *moveToMenu = [[NSMenu alloc] init];
		moveToMenu.delegate = self;
		[moveToItem setSubmenu:moveToMenu];
		
		return  moveToItem;
	}
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
	NSMenu *supermenu = [menu supermenu];
	NSMenuItem *parentMenuItem = [[supermenu itemArray] objectAtIndex:[supermenu indexOfItemWithSubmenu:menu]];
	if (!parentMenuItem || (parentMenuItem.representedObject && ![parentMenuItem.representedObject isKindOfClass:[NSString class]])) return;
	NSManagedObject *parentObject = [DMCurrentManagedObjectContext objectWithUUID:parentMenuItem.representedObject];
	
	// Populate "Move To" menu
	[menu removeAllItems];
	
	if ([parentObject isKindOfClass:[AbstractTask class]]) {
		for (AbstractTask *child in ((AbstractTask *)parentObject).sortedFilteredChildren) {
			[menu addItem:[self moveToMenuItemForTask:child]];
		}
	}
	else { // Root
		NSMutableSet *projects = [DMCurrentManagedObjectContext.dayMap.projects mutableCopy];
		
		if (![[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_ARCHIVED_PROJECTS]) {
			for (Project *project in [projects copy]) {
				if ([project.archived boolValue]) {
					[projects removeObject:project];
				}
			}
		}
		
		[projects addObject:DMCurrentManagedObjectContext.dayMap.inbox];
		if ([DMCurrentManagedObjectContext.dayMap.inbox.sortIndex integerValue] != -1) DMCurrentManagedObjectContext.dayMap.inbox.sortIndex = @(-1);
		NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
		
		for (Project *project in sortedProjects) {
			[menu addItem:[self moveToMenuItemForTask:project]];
		}
	}
}

- (NSArray *)clickedTasks {
	NSInteger clickedRow = [_tasksOutlineView clickedRow];
	if (clickedRow < 0 || clickedRow >= _tasksOutlineView.numberOfRows) {
		return nil;
	}
	
	if ([[_tasksOutlineView selectedRowIndexes] containsIndex:clickedRow]) {
		__block NSMutableArray *selectedTasks = [NSMutableArray array];
		[[_tasksOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[selectedTasks addObject:[_tasksOutlineView itemAtRow:idx]];
		}];
		return selectedTasks;
	}
	else {
		return @[ [_tasksOutlineView itemAtRow:clickedRow] ];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL returnValue = YES;
	
	NSArray *clickedTasks = [self clickedTasks];
	
	if (@selector(edit:) == menuItem.action) {
		return [_tasksOutlineView selectedRowIndexes].count == 1;
	}
	
	else if (@selector(toggleComplete:) == menuItem.action) {
		__block NSMutableArray *selectedTasks = [NSMutableArray array];
		[[_tasksOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			[selectedTasks addObject:[_tasksOutlineView itemAtRow:idx]];
		}];

		BOOL allowed = (selectedTasks.count > 0);
		BOOL anyUncompleted = NO;
		BOOL anyCompleted = NO;
		for (Task *task in selectedTasks) {
			if ([task isCompletedAtDate:nil partial:nil]) {
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
		menuItem.title = NSLocalizedString(@"Show in Calendar", @"context menu");
		return [_tasksOutlineView selectedRowIndexes].count == 1 && ((Task *)[_tasksOutlineView itemAtRow:[_tasksOutlineView selectedRow]]).scheduledDate;
	}
	
	else if (@selector(contextEdit:) == menuItem.action) {
		BOOL allowed = (clickedTasks.count == 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextToggleComplete:) == menuItem.action) {
		BOOL allowed = (clickedTasks.count > 0);
		BOOL anyUncompleted = NO;
		BOOL anyCompleted = NO;
		for (Task *task in clickedTasks) {
			if ([task isCompletedAtDate:nil partial:nil]) {
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
		BOOL allowed = (clickedTasks.count > 0);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextNewTask:) == menuItem.action) {
		BOOL allowed = YES;
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextNewSubtask:) == menuItem.action) {
		BOOL allowed = (clickedTasks.count == 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextShowInOpposingView:) == menuItem.action) {
		BOOL allowed = (clickedTasks.count == 1 && ((Task *)[clickedTasks lastObject]).scheduledDate);
		menuItem.title = NSLocalizedString(@"Show in Calendar", @"context menu");
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextScheduleForToday:) == menuItem.action) {
		BOOL allowed = NO;
		for (Task *task in clickedTasks) {
			if(![task.scheduledDate isEqualToDate:[NSDate today]]) {
				allowed = YES;
			}
			if ([task isCompletedAtDate:nil partial:nil]) {
				allowed = NO;
				break;
			}
			if (task.repeat) {
				allowed = NO;
				break;
			}
		}
		[menuItem setHidden:!allowed];
	}
	
	else if (@selector(contextSelectAll:) == menuItem.action) {
		BOOL allowed = (_tasksOutlineView.numberOfRows > 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
		
	[menuItem.menu cleanUpSeparators];
	
	return returnValue;
}

- (void)contextMoveTo:(id)sender {
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	NSManagedObject *newParent = [DMCurrentManagedObjectContext objectWithUUID:menuItem.representedObject];
	
	WSMoveTasksToParent([self clickedTasks], newParent, 0, NO);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:[newParent valueForKey:@"uuid"] userInfo:nil];
}

- (void)contextEdit:(id)sender {
	Task *task = [[self clickedTasks] lastObject];
	[self editTask:task];
}

- (void)contextToggleComplete:(id)sender {
	[Task toggleCompleted:[self clickedTasks] atDate:nil];
}

- (void)contextDelete:(id)sender {
	for (Task *task in [self clickedTasks]) {
		[DMCurrentManagedObjectContext deleteObject:task];
	}
}

- (void)contextNewTask:(id)sender {
	Task *sibling = [[self clickedTasks] lastObject];
	
	if (!sibling) {
		[self addTask];
	}
	else {
		AbstractTask *parent = sibling.parent;
		NSArray *sortedTasks = [[parent mutableSetValueForKey:@"children"] sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
		NSInteger index = [sortedTasks indexOfObject:sibling] + 1;
		Task *newTask = [Task task];
		((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = newTask.uuid;
		WSMoveTasksToParent(@[newTask], parent, index, NO);
	}
}

- (void)contextNewSubtask:(id)sender {
	Task *parent = [[self clickedTasks] lastObject];
		
	Task *task = [Task task];

	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;

	NSMutableSet *tasks = [parent mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];

	[self expandChildrenOfTask:parent];
}

- (void)contextShowInOpposingView:(id)sender {
	Task *task = [[self clickedTasks] lastObject];
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:task.uuid]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleInCalendarNotification object:nil userInfo:@{@"uuid" : [task valueForKey:@"uuid"]}];
}

- (void)contextScheduleForToday:(id)sender {
	for (Task *task in [self clickedTasks]) {
		task.scheduledDate = [NSDate today];
	}
}

- (void)contextSelectAll:(id)sender {
	[_tasksOutlineView selectAll:sender];
}

@end
