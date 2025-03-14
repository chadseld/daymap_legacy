//
//  MonthViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "MonthViewController.h"
#import "WSTestRectView.h"
#import "NSDate+WS.h"
#import "NSColor+WS.h"
#import "DayMapAppDelegate.h"
#import "MiscUtils.h"
#import "Task+Additions.h"
#import "DayMap.h"
#import "MonthEKEventSectionHeaderTableCellView.h"
#import "MonthEKEventTableCellView.h"
#import "MonthTaskTableCellView.h"


@interface MonthViewController () {
	NSMutableArray *_dayViews;
	NSMutableArray *_filteredTasksForDayViews;
	NSMutableArray *_ekEventsForDayViews;
	
	NSMutableArray *_tableCellViewPool;
	NSMutableArray *_taskTableCellViewPool;
}

@end

@implementation MonthViewController

+ (MonthViewController *)monthViewController {
    id controller = [[self alloc] initWithNibName:@"MonthView" bundle:nil];
    return controller;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DMUpdateWeekViewNotification object:nil];
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"completedDateFilter" context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_EVENTKIT_EVENTS context:NULL];
}

- (void)awakeFromNib {
	_tableCellViewPool = [NSMutableArray new];
	_taskTableCellViewPool = [NSMutableArray new];

	// Day views
	_dayViews = [NSMutableArray new];
	_filteredTasksForDayViews = [[NSMutableArray alloc] initWithCapacity:7*NUMBER_OF_WEEKS_IN_MONTH_VIEW];
	_ekEventsForDayViews = [[NSMutableArray alloc] initWithCapacity:7*NUMBER_OF_WEEKS_IN_MONTH_VIEW];
    for (int i=0; i<7*NUMBER_OF_WEEKS_IN_MONTH_VIEW; i++) {
        MonthDayView *dayView = [[MonthDayView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
		dayView.delegate = self;
		dayView.dataSource = self;
        [self.monthView addSubview:dayView];
		[_dayViews addObject:dayView];
    }
	
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];
	
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"completedDateFilter" options:0 context:(__bridge void*)self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tasksNeedUpdate:) name:DMUpdateWeekViewNotification object:nil];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_SHOW_EVENTKIT_EVENTS options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"selectedTasks"]) {
			[self updateSelection];
        }
		else if([keyPath isEqualToString:@"completedDateFilter"]) {
			[self reloadData];
		}
    }
	else if ([keyPath isEqualToString:PREF_SHOW_EVENTKIT_EVENTS]) {
		[self reloadData];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)tasksNeedUpdate:(NSNotification *)notification {
    [self reloadData];
}

- (void)reloadData {
	NSDate *startDay = [self.dataSource calendarRangeStartDay:self];
	[_filteredTasksForDayViews removeAllObjects];
	[_ekEventsForDayViews removeAllObjects];
	
    for (int i=0; i<7*NUMBER_OF_WEEKS_IN_MONTH_VIEW; i++) {
		MonthDayView *dayView = (MonthDayView *)[_dayViews objectAtIndex:i];
        dayView.day = [startDay dateByAddingDays:i];
    }
	[self updateSelection];
}

- (void)updateSelection {
	NSSet *selectedTasks = [(DayMapAppDelegate *)[NSApp delegate] selectedTasks];
	for (MonthDayView *view in _dayViews) {
		[view updateSelection:selectedTasks];
	}
}

- (void)hoverScrollViewIsHovering:(HoverScrollView *)hoverScrollView {
	if (self.topHoverView == hoverScrollView) {
		[self.delegate calendarRangeBack:self];
	}
	if (self.bottomHoverView == hoverScrollView) {
		[self.delegate calendarRangeForward:self];
	}
}

#pragma mark - MonthViewDelegate

- (void)monthViewDidSwipeForward:(MonthView *)monthView {
	[self.delegate calendarRangeForward:self];
}

- (void)monthViewDidSwipeBackward:(MonthView *)monthView {
	[self.delegate calendarRangeBack:self];
}

- (void)monthViewDidScrollWheel:(NSEvent *)event {
	[self.delegate calendarRange:self scrollWithEvent:event];
}

#pragma mark - MonthDayViewDelegate

- (BOOL)monthDayView:(MonthDayView *)monthDayView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];

	if ([rowIndexes countOfIndexesInRange:NSMakeRange(0, sortedDayTasks.count)] != rowIndexes.count) {
		return NO;
	}
	
	// Copy the row numbers to the pasteboard.
    [Task placeTasks:[sortedDayTasks objectsAtIndexes:rowIndexes] onPasteboard:pboard fromDate:monthDayView.day];

	return YES;
}

- (BOOL)monthDayView:(MonthDayView *)monthDayView acceptDrop:(id <NSDraggingInfo>)info {
    NSPasteboard *pboard = [info draggingPasteboard];
	NSDate *fromDate = nil;
    NSArray *droppedTasks = [Task tasksFromPasteboard:pboard fromDate:&fromDate];

    for (Task *task in droppedTasks) {
		[task setScheduledDate:monthDayView.day handlingRecurrenceAtDate:fromDate];
	}
	
    return YES;
}

- (void)monthDayView:(MonthDayView *)monthDayView didSelectRowsWithIndexes:(NSIndexSet *)rowIndexes {

	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];
	
	NSArray *selectedTasks = [sortedDayTasks objectsAtIndexes:rowIndexes];
	NSSet *selectedTaskIds = [NSSet setWithArray:[selectedTasks valueForKey:@"uuid"]];
	
//    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self]; // turn off observing, so that we don't clear our own selection
    [(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:selectedTaskIds];
//    [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];
}

- (void)monthDayView:(MonthDayView *)monthDayView showWeek:(NSDate *)week {
	[self.delegate calendarRange:self showWeek:week];
}

- (void)monthDayViewAddTask:(MonthDayView *)monthDayView {
	Task *task = [Task task];
	
	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;

	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	if ([NSNull null] == _filteredTasksForDayViews[indexOfDayView] || indexOfDayView >= _filteredTasksForDayViews.count) {
		[self cacheTasksForDayAtIndex:indexOfDayView];
	}
	NSArray *filteredTasks = _filteredTasksForDayViews[indexOfDayView];
	
	task.sortIndexInDay = @([filteredTasks count]);
	[tasks addObject:task];
	task.scheduledDate = monthDayView.day;
}

- (void)monthDayView:(MonthDayView *)monthDayView addSubtaskToTaskAtRow:(NSInteger)rowIndex {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];
	
	if (rowIndex < 0 || rowIndex > sortedDayTasks.count) return;
	
	Task *parent = [sortedDayTasks objectAtIndex:rowIndex];

	Task *task = [Task task];

	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;

	NSMutableSet *tasks = [parent mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];

	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [parent valueForKey:@"uuid"]}];

	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:parent.uuid userInfo:nil];
}

- (void)monthDayView:(MonthDayView *)monthDayView unscheduleRowsWithIndexes:(NSIndexSet *)rowIndexes {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];
	
	NSArray *selectedTasks = [sortedDayTasks objectsAtIndexes:rowIndexes];
	
	for (Task *task in selectedTasks) {
		[task setScheduledDate:nil handlingRecurrenceAtDate:monthDayView.day];
	}
}

- (void)monthDayView:(MonthDayView *)monthDayView toggleCompletedRowsWithIndexes:(NSIndexSet *)rowIndexes {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];
	
	NSArray *selectedTasks = [sortedDayTasks objectsAtIndexes:rowIndexes];
	
	[Task toggleCompleted:selectedTasks atDate:monthDayView.day];
}

- (void)monthDayView:(MonthDayView *)monthDayView showInOutlineViewRowWithIndex:(NSInteger)rowIndex {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	NSArray *sortedDayTasks = _filteredTasksForDayViews[indexOfDayView];

	if (rowIndex < 0 || rowIndex > sortedDayTasks.count) return;
	
	Task *task = [sortedDayTasks objectAtIndex:rowIndex];
	[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:task.uuid]];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [task valueForKey:@"uuid"]}];
}

- (void)monthDayViewDidChangeResponderStatus:(MonthDayView *)monthDayView {
	[self updateSelection];
}

- (NSDate *)dayOfFirstResponder {
	if ([self.view.window.firstResponder isKindOfClass:[MonthDayView class]]) {
		return [(MonthDayView *)self.view.window.firstResponder day];
	}
	return nil;
}

- (void)makeViewWithDayFirstResponder:(NSDate *)day {
	day = [day dateQuantizedToDay];
	for (MonthDayView *dayView in _dayViews) {
		if ([[dayView.day dateQuantizedToDay] isEqualToDate:day]) {
			[dayView.window makeFirstResponder:dayView];
			return;
		}
	}
}

#pragma mark - MonthDayViewDataSource

- (NSArray *)sortTasks:(NSArray *)tasks forDay:(NSDate *)day {
	// Pre-load sort indexes to avoid speed impact of so many core data fetches
	NSMutableArray *sortIndexes = [[NSMutableArray alloc] initWithCapacity:tasks.count];
	for (Task *task in tasks) {
		[sortIndexes addObject:@([task sortIndexInDayForDate:day])];
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

- (void)cacheTasksForDayAtIndex:(NSInteger)index {
	// Load Tasks
	NSDate *day = [[self.dataSource calendarRangeStartDay:self] dateByAddingDays:index];
	NSArray *tasksForDay = [(DayMapAppDelegate *)[NSApp delegate] tasksForDay:day];
	NSArray *filteredTasksForDay = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:tasksForDay], [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], day, nil);
	filteredTasksForDay = [self sortTasks:filteredTasksForDay forDay:day];

	while (_filteredTasksForDayViews.count <= index) {
		[_filteredTasksForDayViews addObject:[NSNull null]];
	}
	[_filteredTasksForDayViews replaceObjectAtIndex:index withObject:filteredTasksForDay];
}

- (void)cacheEKEvents {
	// Load EKEvents
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_EVENTKIT_EVENTS]) {
		NSDate *start = [self.dataSource calendarRangeStartDay:self];
		NSDate *end = [start dateByAddingDays:7*NUMBER_OF_WEEKS_IN_MONTH_VIEW];
		NSArray *eventsForDays = [[(DayMapAppDelegate *)[NSApp delegate] eventKitBridge] eventsForDaysInRangeFromDate:start toDate:end];
		for (int i = 0; i < 7*NUMBER_OF_WEEKS_IN_MONTH_VIEW; i++) {
			if (i < eventsForDays.count) {
				_ekEventsForDayViews[i] = eventsForDays[i];
			}
			else {
				_ekEventsForDayViews[i] = [NSNull null];
			}
		}
	}
}

- (NSInteger)numberOfRowsInMonthDayView:(MonthDayView *)monthDayView {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];
	if (indexOfDayView >= _filteredTasksForDayViews.count || [NSNull null] == _filteredTasksForDayViews[indexOfDayView]) {
		[self cacheTasksForDayAtIndex:indexOfDayView];
	}
	if (indexOfDayView >= _ekEventsForDayViews.count) {
		[self cacheEKEvents];
	}

	NSInteger count = 0;
	count += [_filteredTasksForDayViews[indexOfDayView] count];
	
	if (_ekEventsForDayViews.count > indexOfDayView && _ekEventsForDayViews[indexOfDayView] != [NSNull null]) {
		count += 1;
		count += [_ekEventsForDayViews[indexOfDayView] count];
	}

	return count;
}

- (NSTableCellView *)monthDayView:(MonthDayView *)monthDayView viewForRow:(NSInteger)row {
	NSInteger indexOfDayView = [_dayViews indexOfObject:monthDayView];

	if (indexOfDayView >= _filteredTasksForDayViews.count || [NSNull null] == _filteredTasksForDayViews[indexOfDayView]) {
		[self cacheTasksForDayAtIndex:indexOfDayView];
	}
	if (indexOfDayView >= _ekEventsForDayViews.count) {
		[self cacheEKEvents];
	}
	
	if (row < [_filteredTasksForDayViews[indexOfDayView] count]) {
		Task *task = _filteredTasksForDayViews[indexOfDayView][row];
		MonthTaskTableCellView *result = (MonthTaskTableCellView *)[self dequeueTaskCellViewWithIdentifier:@"MonthTaskTableCellView" task:task];
		if (!result) {
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"MonthTaskTableCellView" bundle:nil];
			result = (MonthTaskTableCellView *)throwAwayViewController.view;
			result.identifier = @"MonthTaskTableCellView";
			[self addTaskCellViewToPool:result];
		}
		result.day = monthDayView.day;
		result.task = task;
		return result;
	}
	else if (row == [_filteredTasksForDayViews[indexOfDayView] count]) {
		// EKEvent Header
		MonthEKEventSectionHeaderTableCellView *result = (MonthEKEventSectionHeaderTableCellView *)[self dequeueCellViewWithIdentifier:@"MonthEKEventSectionHeaderTableCellView"];
		if (!result) {
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"MonthEKEventSectionHeaderTableCellView" bundle:nil];
			result = (MonthEKEventSectionHeaderTableCellView *)throwAwayViewController.view;
			result.identifier = @"MonthEKEventSectionHeaderTableCellView";
			[self addCellViewToPool:result];
		}
		return result;
	}
	else {
		// EKEvent
		MonthEKEventTableCellView *result = (MonthEKEventTableCellView *)[self dequeueCellViewWithIdentifier:@"MonthEKEventTableCellView"];
		if (!result) {
			NSViewController *throwAwayViewController = [[NSViewController alloc] initWithNibName:@"MonthEKEventTableCellView" bundle:nil];
			result = (MonthEKEventTableCellView *)throwAwayViewController.view;
			result.identifier = @"MonthEKEventTableCellView";
			[self addCellViewToPool:result];
		}
		NSInteger index = row - [_filteredTasksForDayViews[indexOfDayView] count] - 1;
		EKEvent *event = _ekEventsForDayViews[indexOfDayView][index];
		result.event = event;
		return result;
	}
}

- (void)addCellViewToPool:(NSTableCellView *)cellView {
	[_tableCellViewPool addObject:cellView];
}

- (void)addTaskCellViewToPool:(NSTableCellView *)cellView {
	[_taskTableCellViewPool addObject:cellView];
}

- (NSTableCellView *)dequeueCellViewWithIdentifier:(NSString *)identifier {
	for (NSInteger i = _tableCellViewPool.count - 1; i >= 0; i--) {
		NSTableCellView *view = _tableCellViewPool[i];
		if (nil == view.superview && [view.identifier isEqualToString:identifier]) {
			return view;
		}
	}
	return nil;
}

- (NSTableCellView *)dequeueTaskCellViewWithIdentifier:(NSString *)identifier task:(Task *)task {
	for (MonthTaskTableCellView *view in _taskTableCellViewPool) {
		if (nil == view.superview && view.task == task) {
			return view;
		}
	}
	for (NSInteger i = _taskTableCellViewPool.count - 1; i >= 0; i--) {
		NSTableCellView *view = _taskTableCellViewPool[i];
		if (nil == view.superview && [view.identifier isEqualToString:identifier]) {
			return view;
		}
	}
	return nil;
}

@end
