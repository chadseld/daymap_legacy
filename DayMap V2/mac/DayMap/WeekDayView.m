//
//  DayView.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/19/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "WeekDayView.h"
#import "Task.h"
#import "Task+Additions.h"
#import "CalendarTaskTableCellView.h"
#import "CalendarEKEventTableCellView.h"
#import "CalendarEKEventSectionHeaderTableCellView.h"
#import "DayMapAppDelegate.h"
#import "TaskTableRowView.h"
#import "MiscUtils.h"
#import "DayMapManagedObjectContext.h"
#import "DayMap.h"
#import "Project.h"
#import "NSColor+WS.h"
#import "DayTableView.h"
#import "NSDate+WS.h"
#import "NSMenu+WS.h"
#import "CascadingVerticalOnlyScrollView.h"
#import <EventKit/EKEvent.h>

#define TASK_HEIGHT 25

@interface WeekDayView () {
    NSScrollView *_tasksScrollView;
	NSTableView *_tasksTableView;
	BOOL _amUpdatingSelection;
}

@property (atomic, strong) NSArray *filteredTasks;
@property (atomic, strong) NSArray *ekEvents;

@end


@implementation WeekDayView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
		// Create Table View
		_tasksTableView = [[DayTableView alloc] initWithFrame:self.bounds];
        [_tasksTableView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_tasksTableView setBackgroundColor:[NSColor whiteColor]];
		[_tasksTableView setIntercellSpacing:NSMakeSize(2, 0)];
        [_tasksTableView setVerticalMotionCanBeginDrag:YES];
        [_tasksTableView registerForDraggedTypes:[NSArray arrayWithObject:DMTaskTableViewDragDataType]];
        [_tasksTableView setHeaderView:nil];
        [_tasksTableView setFocusRingType:NSFocusRingTypeNone];
		[_tasksTableView setAllowsMultipleSelection:YES];
		[_tasksTableView setMenu:[self contextMenu]];
		[_tasksTableView setTarget:self];
		[_tasksTableView setAction:@selector(tableViewAction:)];
		_tasksTableView.delegate = self;
		_tasksTableView.dataSource = self;
		[_tasksTableView setBackgroundColor:[NSColor dayMapCalendarBackgroundColor]];
		NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"task"];
		[_tasksTableView addTableColumn:column];
		
		// Tasks Scroll View
        _tasksScrollView = [[CascadingVerticalOnlyScrollView alloc] initWithFrame:self.bounds];
        [_tasksScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_tasksScrollView setHasVerticalScroller:YES];
        [_tasksScrollView setHasHorizontalScroller:NO];
        [_tasksScrollView setBorderType:NSNoBorder];
        [_tasksScrollView setDrawsBackground:YES];
//		[_tasksScrollView setBackgroundColor:[NSColor yellowColor]];
        [_tasksScrollView setAutohidesScrollers:YES];
        _tasksScrollView.documentView = _tasksTableView;
        [self addSubview:_tasksScrollView];
        
        [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];

		[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"completedDateFilter" options:0 context:(__bridge void*)self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tasksNeedUpdate:) name:DMUpdateWeekViewNotification object:nil];
		
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_SHOW_EVENTKIT_EVENTS options:0 context:NULL];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DMUpdateWeekViewNotification object:nil];
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"completedDateFilter" context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self];
	
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_EVENTKIT_EVENTS context:NULL];
}

- (BOOL)isOpaque
{
    return YES;
}

- (NSArray *)sortTasks:(NSArray *)tasks {
	// Pre-load sort indexes to avoid speed impact of so many core data fetches
	NSMutableArray *sortIndexes = [[NSMutableArray alloc] initWithCapacity:tasks.count];
	for (Task *task in tasks) {
		[sortIndexes addObject:@([task sortIndexInDayForDate:self.day])];
	}

	NSArray *sortedTasks = [tasks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSInteger val1 = [[sortIndexes objectAtIndex:[tasks indexOfObjectIdenticalTo:obj1]] integerValue];
		NSInteger val2 = [[sortIndexes objectAtIndex:[tasks indexOfObjectIdenticalTo:obj2]] integerValue];
		
		if (val1 > val2) {
			return NSOrderedDescending;
		}
		else if (val1 < val2) {
			return NSOrderedAscending;
		}
		else {
			return NSOrderedSame;
		}
	}];

	return sortedTasks;
}

- (void)reloadTasks
{
	// Update filtered tasks and reload table view
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray *tasksForDay = [(DayMapAppDelegate *)[NSApp delegate] tasksForDay:self.day];
		self.filteredTasks = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:tasksForDay], [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], self.day, nil);
		
		self.filteredTasks = [self sortTasks:self.filteredTasks];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_EVENTKIT_EVENTS]) {
			self.ekEvents = [[(DayMapAppDelegate *)[NSApp delegate] eventKitBridge] eventsForDay:self.day];
		}
		else {
			self.ekEvents = nil;
		}
		
		[_tasksTableView reloadData];
		[self updateSelection];
	});
}

- (void)tasksNeedUpdate:(NSNotification *)notification
{
    [self reloadTasks];
}

- (void)updateSelection
{
	_amUpdatingSelection = YES;
	BOOL selected = NO;
	[_tasksTableView selectRowIndexes:[NSIndexSet indexSet]byExtendingSelection:NO];
	for (NSString *taskUUID in [(DayMapAppDelegate *)[NSApp delegate] selectedTasks]) {
		for (NSInteger rowIndex = 0; rowIndex < self.filteredTasks.count; rowIndex++) {
			NSManagedObject *obj = [self.filteredTasks objectAtIndex:rowIndex];
			if ([[obj valueForKey:@"uuid"] isEqual:taskUUID]) {
				[_tasksTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:YES];
				[_tasksTableView scrollRowToVisible:rowIndex];
				selected = YES;
				break;
			}
		}
	}
	if (!selected) {
		[_tasksTableView selectRowIndexes:[NSIndexSet indexSet]byExtendingSelection:NO];
	}
	_amUpdatingSelection = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"selectedTasks"]) {
			[self updateSelection];
        }
		else if ([keyPath isEqualToString:@"completedDateFilter"]) {
			[self reloadTasks];
		}
    }
	else if ([keyPath isEqualToString:PREF_SHOW_EVENTKIT_EVENTS]) {
		[self reloadTasks];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setDay:(NSDate *)day
{
	_day = day;
	[self reloadTasks];
	
	[_tasksTableView setBackgroundColor:[NSColor dayMapCalendarBackgroundColor]];
}

- (IBAction)delete:(id)sender
{
    NSArray *selectedTasks = [self.filteredTasks objectsAtIndexes:[_tasksTableView selectedRowIndexes]];
    for (Task *task in selectedTasks) {
		[task setScheduledDate:nil handlingRecurrenceAtDate:self.day];
    }
}

- (Task *)addTask {
	Task *task = [Task task];
	
	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;
	
	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	task.sortIndexInDay = @([self.filteredTasks count]);
	[tasks addObject:task];
	task.scheduledDate = self.day;
	return task;
}

- (void)editTask:(Task *)task
{
	NSInteger rowIndex = [self.filteredTasks indexOfObject:task];
	if (rowIndex != -1) {
		((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = nil;
		CalendarTaskTableCellView *rowView = [_tasksTableView viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
		[_tasksTableView scrollRowToVisible:rowIndex];
		[_tasksTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
		[_tasksTableView.window makeFirstResponder:_tasksTableView];
		[rowView showPopover];
	}
}

- (IBAction)edit:(id)sender {
	if ([_tasksTableView selectedRow] == -1) return;
	
	[self editTask:[self.filteredTasks objectAtIndex:[_tasksTableView selectedRow]]];
}

- (IBAction)toggleComplete:(id)sender {
	NSArray *selectedTasks = [self.filteredTasks objectsAtIndexes:[_tasksTableView selectedRowIndexes]];
	[Task toggleCompleted:selectedTasks atDate:self.day];
}

- (IBAction)showInOpposingView:(id)sender {
	if ([_tasksTableView selectedRow] == -1) return;

	Task *task = [self.filteredTasks objectAtIndex:[_tasksTableView selectedRow]];
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:task.uuid]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [task valueForKey:@"uuid"]}];
}

- (void)makeFirstResponder {
	[_tasksTableView.window makeFirstResponder:_tasksTableView];
}

#pragma mark - Table View

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	TaskTableRowView *result = [tableView makeViewWithIdentifier:@"taskRow" owner:self];
	
	// There is no existing cell to reuse so we will create a new one
	if (result == nil) {
		
		// create the new view with a frame of the {0,0} with the width of the table
		// note that the height of the frame is not really relevant, the row-height will modify the height
		// the new text field is then returned as an autoreleased object
		//		NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"TaskTableRowView" bundle:nil];
		//		result = (TaskTableRowView *)throwAwayViewController.view;
		result = [[TaskTableRowView alloc] initWithFrame:NSMakeRect(0, 0, _tasksTableView.bounds.size.width, TASK_HEIGHT)];
		
		// the identifier of the view instance is set to task. This
		// allows it to be re-used
		result.identifier = @"taskRow";
	}
	
	// Configure the view
	
	
	// return the result.
	return result;
}
 
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if (row < self.filteredTasks.count) {
		return YES;
	}
	else {
		return NO;
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSInteger count = 0;
	count += self.filteredTasks.count;
	
	if (self.ekEvents.count > 0) {
		count += 1;
		count += self.ekEvents.count;
	}

	return count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return TASK_HEIGHT;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
	return (row == self.filteredTasks.count);
}

// This method is optional if you use bindings to provide the data
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row < self.filteredTasks.count) {
		Task *task = [self.filteredTasks objectAtIndex:row];
		
		// get an existing cell with the task identifier if it exists
		CalendarTaskTableCellView *result = [tableView makeViewWithIdentifier:@"task" owner:self];
		
		// There is no existing cell to reuse so we will create a new one
		if (result == nil) {
			
			// create the new view with a frame of the {0,0} with the width of the table
			// note that the height of the frame is not really relevant, the row-height will modify the height
			// the new text field is then returned as an autoreleased object
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"CalendarTaskTableCellView" bundle:nil];
			result = (CalendarTaskTableCellView *)throwAwayViewController.view;
			
			// the identifier of the view instance is set to task. This
			// allows it to be re-used
			result.identifier = @"task";
		}
		
		// result is now guaranteed to be valid, either as a re-used cell
		// or as a new cell, so set the value of the cell to the value at row
		result.day = self.day;
		result.task = task;
		
		// return the result.
		return result;
	}
	else if (row == self.filteredTasks.count) {
		// get an existing cell with the task identifier if it exists
		CalendarEKEventSectionHeaderTableCellView *result = [tableView makeViewWithIdentifier:@"EKEventSectionHeader" owner:self];
		
		// There is no existing cell to reuse so we will create a new one
		if (result == nil) {
			
			// create the new view with a frame of the {0,0} with the width of the table
			// note that the height of the frame is not really relevant, the row-height will modify the height
			// the new text field is then returned as an autoreleased object
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"CalendarEKEventSectionHeaderTableCellView" bundle:nil];
			result = (CalendarEKEventSectionHeaderTableCellView *)throwAwayViewController.view;
			
			// the identifier of the view instance is set to task. This
			// allows it to be re-used
			result.identifier = @"EKEventSectionHeader";
		}
		
		// return the result.
		return result;
	}
	else {
		EKEvent *event = [self.ekEvents objectAtIndex:row - self.filteredTasks.count - 1];
		
		// get an existing cell with the task identifier if it exists
		CalendarEKEventTableCellView *result = [tableView makeViewWithIdentifier:@"EKEvent" owner:self];
		
		// There is no existing cell to reuse so we will create a new one
		if (result == nil) {
			
			// create the new view with a frame of the {0,0} with the width of the table
			// note that the height of the frame is not really relevant, the row-height will modify the height
			// the new text field is then returned as an autoreleased object
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"CalendarEKEventTableCellView" bundle:nil];
			result = (CalendarEKEventTableCellView *)throwAwayViewController.view;
			
			// the identifier of the view instance is set to task. This
			// allows it to be re-used
			result.identifier = @"EKEvent";
		}
		
		// result is now guaranteed to be valid, either as a re-used cell
		// or as a new cell, so set the value of the cell to the value at row
		result.event = event;
		
		// return the result.
		return result;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (_amUpdatingSelection) return;
	
    __block NSMutableSet *selectedTasks = [NSMutableSet set];
    [[_tasksTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [selectedTasks addObject:[[self.filteredTasks objectAtIndex:idx] valueForKey:@"uuid"]];
    }];

    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self]; // turn off observing, so that we don't clear our own selection
    [(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:selectedTasks];
    [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];
}

- (void)tableViewAction:(id)sender
{
	if ([[NSApp currentEvent] type] == NSLeftMouseUp && [NSApp currentEvent].clickCount == 2 && [_tasksTableView clickedColumn] >=0 && [_tasksTableView clickedRow] >=0) {
		TaskTableCellView *cellView = [_tasksTableView viewAtColumn:[_tasksTableView clickedColumn] row:[_tasksTableView clickedRow] makeIfNecessary:NO];
		if ([cellView isKindOfClass:[TaskTableCellView class]]) {
			[cellView showPopover];
		}
		else if ([cellView isKindOfClass:[CalendarEKEventTableCellView class]]) {
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.iCal" options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
		}
	}
	else if ([[NSApp currentEvent] type] == NSLeftMouseUp && [NSApp currentEvent].clickCount == 2) {
		[self addTask];
	}
	else {
		// This action is called whenever a mouse is clicked in the table view. Either a row is clicked, or the area under the row is clicked.
		// If the area under the row is clicked, we generate an (possibly additional) selectionDidChange notification. This is because the selection 
		// may be in another table view in the app and we still need to clear it.
		if ([[_tasksTableView selectedRowIndexes] count] == 0) { // if empty selection
			[self tableViewSelectionDidChange:nil];
		}
	}
}

#pragma mark -
#pragma mark Drag & Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	__block BOOL tooHigh = NO;
	[rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		if (idx >= self.filteredTasks.count) {
			tooHigh = YES;
			*stop = YES;
		}
	}];
	if (tooHigh) {
		return NO;
	}
	
    // Copy the row numbers to the pasteboard.
    [Task placeTasks:[self.filteredTasks objectsAtIndexes:rowIndexes] onPasteboard:pboard fromDate:self.day];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropOn) return NSDragOperationNone;
	
	if (row > self.filteredTasks.count) {
		[tableView setDropRow:self.filteredTasks.count dropOperation:operation];
	}

	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)rowIndex dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
	NSDate *fromDate = nil;
    NSArray *droppedTasks = [Task tasksFromPasteboard:pboard fromDate:&fromDate];

	[self reorderTasks:droppedTasks toIndex:rowIndex fromDate:fromDate];

    [self reloadTasks];
    
    return YES;
}

- (void)reorderTasks:(NSArray *)tasks toIndex:(NSInteger)index fromDate:(NSDate *)fromDate {
	NSMutableOrderedSet *orderedTasksForDay = [NSMutableOrderedSet orderedSetWithArray:[self sortTasks:[(DayMapAppDelegate *)[NSApp delegate] tasksForDay:self.day]]];
	
	// We are going to perform these sort/drop operations on the regular, non-completed-filtered, task sets
	// row is possibly incorrect. There may be hidden completed tasks in the list in an index < row.
	// find the item at row in the filtered array, and find the same item in non-filtered array
	// The item index in the non-filtered array should be used as row
	if (index < 0 || index >= [self.filteredTasks count]) {
		index = [orderedTasksForDay count];
	}
	else {
		Task *hitTask = [self.filteredTasks objectAtIndex:index];
		index = [orderedTasksForDay indexOfObject:hitTask];
	}
	
    for (Task *task in tasks) {
		if (![self.day isEqualToDate:fromDate] &&
			(![[fromDate dateQuantizedToDay] isEqualToDate:[self.day dateQuantizedToDay]] ||
			![[task.completedDate dateQuantizedToDay] isEqualToDate:[self.day dateQuantizedToDay]])) {
			[task setScheduledDate:self.day handlingRecurrenceAtDate:fromDate];
		}
	}
	
	for (Task *task in tasks) {
		NSInteger taskIndex = [orderedTasksForDay indexOfObject:task];
		if (NSNotFound == taskIndex) {
			continue;
		}
		[orderedTasksForDay removeObjectAtIndex:taskIndex];
		if (taskIndex < index) index --;
	}
	
	for (Task *task in tasks) {
		[orderedTasksForDay insertObject:task atIndex:index];
		index++;
	}
	
	// Update sort index
	NSInteger i = 0;
	for (Task *task in orderedTasksForDay) { // update sortIndex
		[task setSortIndexInDay:[NSNumber numberWithInteger:i] forDate:self.day];
		i++;
	}
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
	
/*	if(RETURN_KEY == key ||
	   ENTER_KEY == key) {
		[self editTask:[self.filteredTasks objectAtIndex:[_tasksTableView selectedRow]]];
	}
	else */if(SPACE_KEY == key) {
		[Task toggleCompleted:[self.filteredTasks objectsAtIndexes:[_tasksTableView selectedRowIndexes]] atDate:self.day];
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
	
	[menu addItemWithTitle:NSLocalizedString(@"New Task…", @"context menu") action:@selector(contextNewTask:) keyEquivalent:@""];
	[menu addItemWithTitle:NSLocalizedString(@"New Subtask…", @"context menu") action:@selector(contextNewSubtask:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Show", @"context menu") action:@selector(contextShowInOpposingView:) keyEquivalent:@""];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:NSLocalizedString(@"Select All", @"context menu") action:@selector(contextSelectAll:) keyEquivalent:@""];
	
	return menu;
}

- (NSArray *)clickedTasks {
	NSInteger clickedRow = [_tasksTableView clickedRow];
	if (clickedRow < 0 || clickedRow >= self.filteredTasks.count) {
		return nil;
	}
		
	if ([[_tasksTableView selectedRowIndexes] containsIndex:clickedRow]) {
		return [self.filteredTasks objectsAtIndexes:[_tasksTableView selectedRowIndexes]];
	}
	else {
		return @[ [self.filteredTasks objectAtIndex:clickedRow] ];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL returnValue = YES;
	
	NSArray *clickedTasks = [self clickedTasks];
	
	if (@selector(edit:) == menuItem.action) {
		return [_tasksTableView selectedRowIndexes].count == 1;
	}
	
	else if (@selector(toggleComplete:) == menuItem.action) {
		NSArray *selectedTasks = [self.filteredTasks objectsAtIndexes:[_tasksTableView selectedRowIndexes]];
		
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
		return [_tasksTableView selectedRowIndexes].count == 1;
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
		BOOL allowed = (clickedTasks.count > 0);
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
		BOOL allowed = (clickedTasks.count == 1);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextShowInOpposingView:) == menuItem.action) {
		BOOL allowed = (clickedTasks.count == 1);
		menuItem.title = NSLocalizedString(@"Show in Outline", @"context menu");
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	else if (@selector(contextScheduleForToday:) == menuItem.action) {
		BOOL allowed = NO;
		for (Task *task in clickedTasks) {
			if(![task.scheduledDate isEqualToDate:[NSDate today]]) {
				allowed = YES;
			}
			if ([task isCompletedAtDate:self.day partial:nil]) {
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
		BOOL allowed = (_tasksTableView.numberOfRows > 0);
		//		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}
	
	
	[menuItem.menu cleanUpSeparators];
	
	return returnValue;
}

- (void)contextEdit:(id)sender {
	Task *task = [[self clickedTasks] lastObject];
	[self editTask:task];
}

- (void)contextToggleComplete:(id)sender {
	[Task toggleCompleted:[self clickedTasks] atDate:self.day];
}

- (void)contextDelete:(id)sender {
	for (Task *task in [self clickedTasks]) {
		[task setScheduledDate:nil handlingRecurrenceAtDate:self.day];
	}
}

- (void)contextNewTask:(id)sender {
	Task *sibling = [[self clickedTasks] lastObject];

	Task *task = [self addTask];

	if (sibling) {
		NSInteger index = [sibling.sortIndexInDay integerValue] + 1;
		[self reorderTasks:@[task] toIndex:index fromDate:nil];
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

	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [parent valueForKey:@"uuid"]}];

	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:parent.uuid userInfo:nil];
}

- (void)contextShowInOpposingView:(id)sender {
	Task *task = [[self clickedTasks] lastObject];
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:task.uuid]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [task valueForKey:@"uuid"]}];
}

- (void)contextScheduleForToday:(id)sender {
	for (Task *task in [self clickedTasks]) {
		task.scheduledDate = [NSDate today];
	}
}

- (void)contextSelectAll:(id)sender {
	[_tasksTableView selectAll:sender];
}

@end
