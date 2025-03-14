//
//  CalendarViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/11/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarViewController.h"
#import "DayMapAppDelegate.h"

#import "NSDate+WS.h"
#import "NSBezierPath+WS.h"
#import "NSDate+WS.h"
#import "CalendarPopoverViewController.h"
#import "Task.h"

@implementation CalendarViewController

@synthesize week = _week;

- (id)init
{
    self = [super initWithNibName:@"CalendarView" bundle:nil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS context:NULL];
}

- (void)awakeFromNib
{
	NSDate *selectedWeek = [[NSUserDefaults standardUserDefaults] objectForKey:PREF_CURRENTLY_SELECTED_WEEK];
	if (nil == selectedWeek) {
		[self showToday:self];
	}
	else {
		self.week = selectedWeek;
	}

	// Week Selection
	self.weekSelectionWidget.delegate = self;

	// Calendar view
	self.calendarViewByMode = (DMCalendarViewByMode)[[NSUserDefaults standardUserDefaults] integerForKey:PREF_CALENDAR_VIEW_MODE];
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeTaskVisibleNotification:) name:DMMakeTaskVisibleInCalendarNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeManagedObjectContextNotification:) name:DMWillChangeManagedObjectContext object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeManagedObjectContextNotification:) name:DMDidChangeManagedObjectContext object:nil];

	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS options:NSKeyValueObservingOptionNew
											   context:NULL];

	[self onMidnightTimer];
}

- (void)configureForViewByWeek {
	if (nil == self.weekViewController) {
		self.weekViewController = [WeekViewController weekViewController];
		self.weekViewController.delegate = self;
		self.weekViewController.dataSource = self;
	}
	
	self.calendarHeaderView.contentView = self.weekViewController.view;
	[self.weekViewController reloadData];
	
	self.weekSelectionWidget.daysDuration = 7;
}

- (void)configureForViewByMonth {
	if (nil == self.monthViewController) {
		self.monthViewController = [MonthViewController monthViewController];
		self.monthViewController.delegate = self;
		self.monthViewController.dataSource = self;
	}
	
	self.calendarHeaderView.contentView = self.monthViewController.view;
	[self.monthViewController reloadData];
	
	self.weekSelectionWidget.daysDuration = 7 * NUMBER_OF_WEEKS_IN_MONTH_VIEW;
}

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification {
}

- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	[self updateDayViews];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
    }
	else if ([keyPath isEqualToString:PREF_SHOW_ARCHIVED_PROJECTS]) {
		[self updateDayViews];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)makeTaskVisibleNotification:(NSNotification *)notification
{
	NSString *taskUUID = [[notification userInfo] objectForKey:@"uuid"];
	
	Task *task = (Task *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
	if (task.scheduledDate) {
		[self setWeek:task.scheduledDate];
		
		if (DMCalendarViewByMonth == self.calendarViewByMode) {
			[self.monthViewController makeViewWithDayFirstResponder:task.scheduledDate];
		}
		else {
			[self.weekViewController makeViewWithDayFirstResponder:task.scheduledDate];
		}
	}
}

- (void)setCalendarViewByMode:(DMCalendarViewByMode)calendarViewByMode {
	NSDate *selectedDate = [self.weekViewController dayOfFirstResponder];
	if (nil == selectedDate) selectedDate = [self.monthViewController dayOfFirstResponder];
	
	_calendarViewByMode = calendarViewByMode;
	if (DMCalendarViewByMonth == _calendarViewByMode) {
		[self configureForViewByMonth];
		[self.monthViewController makeViewWithDayFirstResponder:selectedDate];
	}
	else {
		[self configureForViewByWeek];
		[self.weekViewController makeViewWithDayFirstResponder:selectedDate];
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:_calendarViewByMode forKey:PREF_CALENDAR_VIEW_MODE];
}

- (NSDate *)week
{
	@synchronized(self) {
		return _week;
	}
}

- (void)setWeek:(NSDate *)week
{
	// TODO: we may want to change the WSCalendarRangeViewController to have a
	// setStartDay or startDayChanged so that it knows how to updated its view
	// without having to reload all data as in reloadData. This method would
	// allow the view to keep existing days and only load tasks for the new days.
	
	@synchronized(self) {
		if (_week == week) return;
		
		_week = [[week beginningOfWeek] copy];

		// Save to prefs
		if ([[week beginningOfWeek] isEqualToDate:[[NSDate today] beginningOfWeek]]) { // current week is selected, remove pref so that we advance naturally
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_CURRENTLY_SELECTED_WEEK];
		}
		else { // something other than current week is selected, save it
			[[NSUserDefaults standardUserDefaults] setObject:_week forKey:PREF_CURRENTLY_SELECTED_WEEK];
		}

		[self updateDayViews];
		[self.calendarHeaderView setNeedsDisplay:YES];
		self.weekSelectionWidget.week = _week;
	}
}

- (void)onMidnightTimer {
	[self updateDayViews];

	NSDate *now = [NSDate today];
	NSDate *midnight = [[[now dateQuantizedToDay] dateByAddingDays:1] dateByAddingTimeInterval:10]; // 10 seconds after midnight
	NSInteger delta = [midnight timeIntervalSinceDate:now];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delta * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self onMidnightTimer];
	});
}

- (void)updateDayViews
{
	if (!DMCurrentManagedObjectContext) return;
	
	if (DMCalendarViewByMonth == self.calendarViewByMode) {
		[self.monthViewController reloadData];
	}
	else {
		[self.weekViewController reloadData];
	}
}

- (IBAction)showCalendarPopover:(id)sender 
{
    NSPopover *popover = [[NSPopover alloc] init];
	popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.animates = YES;
    
    CalendarPopoverViewController *viewController = [CalendarPopoverViewController calendarPopoverViewController];
    viewController.popover = popover;
    popover.contentViewController = viewController;
	popover.delegate = viewController;
    viewController.calendarViewController = self;
    
    [popover showRelativeToRect:((NSView *)sender).bounds ofView:sender preferredEdge:CGRectMinYEdge];
}

- (IBAction)forwardDateRange:(id)sender {
	self.week = [self.week dateByAddingDays:self.weekSelectionWidget.daysDuration];
}

- (IBAction)backDateRange:(id)sender {
	self.week = [self.week dateByAddingDays:-self.weekSelectionWidget.daysDuration];
}

- (IBAction)showToday:(id)sender {
	self.week = [[NSDate today] beginningOfWeek];
}

#pragma mark - WSCalendarRangeViewController delegate & dataSource

- (NSDate *)calendarRangeStartDay:(WSCalendarRangeViewController *)viewController {
	return self.week;
}

- (void)calendarRangeForward:(WSCalendarRangeViewController *)viewController {
	[self forwardDateRange:nil];
}

- (void)calendarRangeBack:(WSCalendarRangeViewController *)viewController {
	[self backDateRange:nil];
}

- (void)calendarRange:(WSCalendarRangeViewController *)viewController showWeek:(NSDate *)week {
	self.week = week;
	self.calendarViewByMode = DMCalendarViewByWeek;
}

- (void)calendarRange:(WSCalendarRangeViewController *)viewController scrollWithEvent:(NSEvent *)event {
	static CGFloat amount = 0;
	
	if (event.momentumPhase != NSEventPhaseNone) {
		return;
	}
	
	if (NSEventPhaseBegan == event.phase || NSEventPhaseEnded == event.phase) {
		amount = 0;
	}
	
	if (DMCalendarViewByMonth == self.calendarViewByMode) {
		// Scroll vertically by weeks
		amount += event.deltaY;
		
		const CGFloat kThreshold = 5;
		if (amount < -kThreshold) {
			self.week = [[self.week dateByAddingDays:7] beginningOfWeek];
			amount += kThreshold;
		}
		else if (amount > kThreshold) {
			self.week = [[self.week dateByAddingDays:-7] beginningOfWeek];
			amount -= kThreshold;
		}

	}
	else {
		// Scroll horizontally by days
		// On second thought, this is very confusing if we can't scroll by pixels the day views.
		// Just changing the start day is jarring
	}
}

@end
