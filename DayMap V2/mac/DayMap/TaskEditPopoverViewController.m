//
//  TaskEditPopoverViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/23/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "TaskEditPopoverViewController.h"
#import "AbstractTask+Additions.h"
#import "Task+Additions.h"
#import "NSDate+WS.h"
#import "RecurrenceRule+Additions.h"
#import "MiscUtils.h"
#import "DMDatePickerPopover.h"
#import "WSRootAppDelegate.h"

@implementation TaskEditPopoverViewController

+ (TaskEditPopoverViewController *)taskEditPopoverViewController
{
    id controller = [[self alloc] initWithNibName:@"TaskEditPopover" bundle:nil];
    return controller;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
    [_task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
    [_task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.frequency" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.endAfterCount" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.endAfterDate" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[self observeValueForKeyPath:@"completed" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"scheduledDate" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"repeat.frequency" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"attributedDetails" ofObject:_task change:nil context:(__bridge void*)self];

	self.scheduledDatePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
	self.endDatePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

	// Hide controls in daymap lite
#ifdef TARGET_DAYMAP_LITE
    [self.expandButton setHidden:YES];

    [self.repeatLabel setHidden:YES];
    [self.endLabel setHidden:YES];
    [self.repeatPopUpButton setHidden:YES];
    [self.endPopUpButton setHidden:YES];
    [self.endNumberOfTimesTextField setHidden:YES];
    [self.endDatePicker setHidden:YES];
    [self.endTimesLabel setHidden:YES];

    // Adjust layout
	[self.view removeConstraint:self.notesTopConstraint];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[date]-20-[notes]" options:0 metrics:nil views:@{@"date" : self.scheduledDatePicker, @"notes" : self.descriptionScrollView}]];
#endif
}

- (void)popoverWillShow:(NSNotification *)notification {
	[[self.nameTextField window] setInitialFirstResponder:self.nameTextField];
}

- (void)popoverDidClose:(NSNotification *)notification
{
	NSPopover *popover = [notification object];
	popover.contentViewController = nil;
}

- (IBAction)done:(id)sender
{
	[[self.nameTextField window] makeFirstResponder:nil];
    [self.popover performClose:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"completed"] ||
			[keyPath isEqualToString:@"completedDate"] ||
			[keyPath isEqualToString:@"repeat.completions"] ||
			[keyPath isEqualToString:@"repeat.exceptions"]) {
			BOOL partial = NO;
			BOOL complete = [self.task isCompletedAtDate:self.shownForDay partial:&partial];
			if (partial) {
				[self.completedCheckbox setState:NSMixedState];
			}
			else {
				[self.completedCheckbox setState:complete ? NSOnState : NSOffState];
			}
        }
		if ([keyPath isEqualToString:@"scheduledDate"]) {
			[self willChangeValueForKey:@"scheduledDate"];
			[self didChangeValueForKey:@"scheduledDate"];
		}
		else if ([keyPath isEqualToString:@"repeat.frequency"] ||
				 [keyPath isEqualToString:@"repeat.endAfterCount"] ||
				 [keyPath isEqualToString:@"repeat.endAfterDate"]) {
			[self updateRepeatMenu];
			[self updateEndMenu];
			[self updateEndOptions];
			[self willChangeValueForKey:@"endAfterDate"];
			[self didChangeValueForKey:@"endAfterDate"];
		}
		else if ([keyPath isEqualToString:@"attributedDetails"]) {
			[self willChangeValueForKey:@"attributedDetails"];
			[self didChangeValueForKey:@"attributedDetails"];
		}
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSAttributedString *)attributedDetails {
	return _task.attributedDetailsAttributedString;
}

- (void)setAttributedDetails:(NSAttributedString *)attributedDetails {
	_task.attributedDetailsAttributedString = attributedDetails;
}

- (void)setTask:(Task *)task
{
    [_task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
    [_task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.frequency" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.endAfterCount" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.endAfterDate" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[_task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
    _task = task;
    [_task addObserver:self forKeyPath:@"completed" options:0 context:(__bridge void*)self];
    [_task addObserver:self forKeyPath:@"completedDate" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"scheduledDate" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"repeat.frequency" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"repeat.endAfterCount" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"repeat.endAfterDate" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"attributedDetails" options:0 context:(__bridge void*)self];
	[_task addObserver:self forKeyPath:@"repeat.completions" options:0 context:(__bridge void*)self];
    [_task addObserver:self forKeyPath:@"repeat.exceptions" options:0 context:(__bridge void*)self];

    [self observeValueForKeyPath:@"completed" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"scheduledDate" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"repeat.frequency" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"repeat.endAfterCount" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"repeat.endAfterDate" ofObject:_task change:nil context:(__bridge void*)self];
	[self observeValueForKeyPath:@"attributedDetails" ofObject:_task change:nil context:(__bridge void*)self];
}

- (IBAction)toggleCompleted:(id)sender
{
	[self.task toggleCompletedAtDate:self.shownForDay partial:WSIsOptionKeyPressed()];
}

- (void)updateRepeatMenu {
	if (self.task.repeat) {
		[self.repeatPopUpButton selectItemWithTag:[self.task.repeat.frequency integerValue]];
	}
	else {
		[self.repeatPopUpButton selectItemWithTag:-1];
	}
}

- (IBAction)repeatFrequencyChanged:(id)sender {
	NSInteger tag = [self.repeatPopUpButton selectedTag];
	
	if (-1 == tag) {
		if (self.task.repeat) {
			[DMCurrentManagedObjectContext deleteObject:self.task.repeat];
		}
	}
	else {
		if (nil == self.task.repeat) {
			self.task.repeat = [RecurrenceRule recurrenceRule];
		}
		self.endDate = nil;
		self.task.repeat.endAfterCount = 0;
		self.task.repeat.frequency = @(tag);
	}
	[self updateEndMenu];
}

- (void)updateEndMenu {
	NSInteger tag = [self.repeatPopUpButton selectedTag];
	[self.endPopUpButton setEnabled:(-1 != tag)];

	NSDate *endDate = self.task.repeat.endAfterDate;
	NSInteger endCount = [self.task.repeat.endAfterCount integerValue];
	if (nil == endDate && 0 == endCount) {
		[self.endPopUpButton selectItemAtIndex:0];
	}
	else if (endCount > 0) {
		[self.endPopUpButton selectItemAtIndex:1];
	}
	else if (nil != endDate) {
		[self.endPopUpButton selectItemAtIndex:2];
	}
}

- (IBAction)endMenuChanged:(id)sender {
	NSUInteger selectedIndex = [self.endPopUpButton indexOfSelectedItem];
	if(0 == selectedIndex) { // Never
		self.task.repeat.endAfterCount = @(0);
		self.endDate = nil;
	}
	else if (1 == selectedIndex) { // After n times
		self.endDate = nil;
		if (0 == [self.task.repeat.endAfterCount integerValue]) {
			self.task.repeat.endAfterCount = @(3);
		}
	}
	else if (2 == selectedIndex) { // On Date
		self.task.repeat.endAfterCount = @(0);
		if (nil == self.task.repeat.endAfterDate) {
			self.endDate = [self.scheduledDate dateByAddingWeeks:1];
		}
	}
	[self updateEndOptions];
}

- (void)updateEndOptions {
	NSUInteger selectedIndex = [self.endPopUpButton indexOfSelectedItem];
	if(0 == selectedIndex) { // Never
		[self.endNumberOfTimesTextField setHidden:YES];
		[self.endDatePicker setHidden:YES];
		[self.endTimesLabel setHidden:YES];
	}
	else if (1 == selectedIndex) { // After n times
		[self.endNumberOfTimesTextField setHidden:NO];
		[self.endDatePicker setHidden:YES];
		[self.endTimesLabel setHidden:NO];
	}
	else if (2 == selectedIndex) { // On Date
		[self.endNumberOfTimesTextField setHidden:YES];
		[self.endDatePicker setHidden:NO];
		[self.endTimesLabel setHidden:YES];
	}
}

- (IBAction)clearScheduledDate:(id)sender {
	self.scheduledDate = nil;
}

- (IBAction)scheduleForToday:(id)sender {
	self.scheduledDate = [NSDate today];
}

- (IBAction)showDatePickerPopover:(NSButton *)sender {
	DMDatePickerPopover *datePickerPopover = [[DMDatePickerPopover alloc] init];
	[datePickerPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:CGRectMinYEdge startDate:self.scheduledDate ? : [NSDate today] changeHandler:^(NSDate *date) {
		self.scheduledDate = date;
	}];
}

- (IBAction)expand:(id)sender {
	[sender setHidden:YES];
	NSRect frame = self.view.frame;
	frame.size = NSMakeSize(550, 600);
	[self.popover setContentSize:frame.size];
}

- (NSDate *)scheduledDate {
	return self.task.scheduledDate;
}

- (void)setScheduledDate:(NSDate *)scheduledDate {
	self.task.scheduledDate = [scheduledDate dateQuantizedToDay];
	[self.task.repeat clearExceptions];
}

- (NSDate *)endDate {
	return self.task.repeat.endAfterDate;
}

- (void)setEndDate:(NSDate *)endDate {
	self.task.repeat.endAfterDate = [endDate dateQuantizedToDay];
}

@end
