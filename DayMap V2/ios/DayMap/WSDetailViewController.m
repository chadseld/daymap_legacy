//
//  WSDetailViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/24/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WSDetailViewController.h"
#import "Project.h"
#import "Task+Additions.h"
#import "WSMovePickerTableViewController.h"
#import "WSRichTextTableViewCell.h"
#import "MiscUtils.h"
#import "WSAppDelegate.h"
#import "NSDate+WS.h"
#import "RecurrenceRule+Additions.h"
#import "AbstractTask+Additions.h"


@interface WSDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic, readonly) AbstractTask *detailItem;
@end

@implementation WSDetailViewController

#pragma mark - Managing the detail item


- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	self.detailItemUUID = _detailItemUUID;
	[super didChangeManagedObjectContextNotification:notification];
}

- (void)updateSortedProjects
{
	NSArray *sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES]];
	self.sortedTasks = [[[self.detailItem.children allObjects] sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
    self.sortedTasks = [WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:self.sortedTasks], [(WSAppDelegate *)[NSApp delegate] completedDateFilter], nil, sortDescriptors) mutableCopy];

	[self updateView];
}

- (NSManagedObject *)objectToObserve {
	return self.detailItem;
}

- (NSArray *)keyPathsToObserve {
	if ([self.objectToObserve.entity.name isEqualToString:@"Task"]) {
		return @[@"name", @"completed", @"completedDate", @"scheduledDate", @"repeat.frequency", @"repeat.endAfterCount", @"repeat.endAfterDate", @"attributedDetails", @"repeat.completions", @"repeat.exceptions"];
	}
	else {
		return @[@"name", @"attributedDetails"];
	}
}

- (AbstractTask *)detailItem {
	return (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:_detailItemUUID];
}

- (void)setDetailItemUUID:(NSString *)detailItemUUID
{
	if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }

	_detailItemUUID = detailItemUUID;

	if ([[[self.detailItem entity] name] isEqualToString:@"Tombstone"]) {
		[self.navigationController popViewControllerAnimated:YES];
		return;
	}
	
	// Update the view.
	[self configureViewForItemType];
    [self updateSortedProjects];
	[self.tableView reloadData];
}

- (void)configureViewForItemType
{
    // Update the user interface for the detail item.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

	if (self.detailItem) {
        self.scheduledDateButton.layer.borderWidth = 1;
        self.scheduledDateButton.layer.cornerRadius = 6;
        self.scheduledDateButton.layer.borderColor = [[UIColor dayMapActionColor] CGColor];
        self.moveButton.layer.borderWidth = 1;
        self.moveButton.layer.cornerRadius = 6;
        self.moveButton.layer.borderColor = [[UIColor dayMapActionColor] CGColor];
        self.addTaskButton.layer.borderWidth = 1;
        self.addTaskButton.layer.cornerRadius = 6;
        self.addTaskButton.layer.borderColor = [[UIColor dayMapActionColor] CGColor];

        if([self.detailItem isKindOfClass:[Task class]])
        {
            self.projectColorButton.hidden = YES;
        }
        else { // Project
            self.projectColorButton.hidden = NO;
            self.moveButton.hidden = YES;
            self.scheduledDateButton.hidden = YES;
            self.completedSwitch.hidden = YES;
        }
        //set up for non edit mode
        self.detailTextView.layer.borderWidth = 0.5;
		self.detailTextView.layer.cornerRadius = 5;
        self.detailTextView.layer.borderColor = [[UIColor colorWithRed:0.803922 green:0.803922 blue:0.803922 alpha:1] CGColor];
	}
}

- (void)updateView
{
	AbstractTask *detailItem = self.detailItem;
    if([detailItem isKindOfClass:[Task class]])
    {
        Task *detailTask = (Task *)detailItem;
        
        NSDate *date = [detailTask scheduledDate];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
		dateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [dateFormat setDateStyle:NSDateFormatterLongStyle];
        
        if (detailTask.scheduledDate) {
            [self.scheduledDateButton setTitle:[NSString stringWithFormat:@"%@", [dateFormat stringFromDate:date]] forState:UIControlStateNormal];
        }
        else {
            [self.scheduledDateButton setTitle:@"Tap to Schedule" forState:UIControlStateNormal];
        }
		
        NSInteger completedSegment = 0;
        if(TASK_COMPLETED == [detailTask.completed intValue]) completedSegment = 1;
        [self.completedSwitch setSelectedSegmentIndex:completedSegment];
    }    
    else {
		self.projectColorButton.backgroundColor = [[detailItem valueForKey:@"displayAttributes"] valueForKey:@"nativeColor"];
		self.projectColorButton.layer.cornerRadius = 7;

	}
	
    self.nameTextField.text = [detailItem name];
    self.navigationItem.title = [detailItem name];
	self.detailTextView.attributedText = [detailItem attributedDetailsAttributedString];
    self.descriptionLabel.hidden = (self.detailTextView.text.length != 0);
}


#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    
    // Create and set the table header view.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableHeaderView addGestureRecognizer:tapGesture];
    [self.detailTextView setBackgroundColor:[UIColor whiteColor]];
	
	[self configureViewForItemType];
}

- (void)viewDidUnload
{
    [self setNameTextField:nil];
    [self setDescriptionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	if (![[[self.detailItem entity] name] isEqualToString:@"Tombstone"]) {
		[self nameEdited:nil];
		[self textViewDidEndEditing:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

#pragma mark -
#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
	
	[self.tableView beginUpdates];
	
    NSUInteger taskCount = [self.sortedTasks count];
    
    NSArray *taskInsertIndexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:taskCount inSection:0]];
    
    if (editing) {
        if([self.tableView numberOfRowsInSection:0] > taskCount)
            [self.tableView deleteRowsAtIndexPaths:taskInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
	} else {
        [self.tableView insertRowsAtIndexPaths:taskInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
    }
    
    [self.tableView endUpdates];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.sortedTasks count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WSRichTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditableCell"];
    cell.shouldItalicize = YES;
    cell.textField.enabled = YES;
    cell.completedButton.hidden = NO;
    Task *task = [self.sortedTasks objectAtIndex:[indexPath row]];
    cell.task = task;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        [DMCurrentManagedObjectContext deleteObject:[self.sortedTasks objectAtIndex:[indexPath row]]];
        [self.detailItem removeChildrenObject:[self.sortedTasks objectAtIndex:[indexPath row]]];
        [self.sortedTasks removeObjectAtIndex:[indexPath row]];
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [tableView endUpdates];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
        // If this is the last item, it's the insertion row.
        if (indexPath.row == [self.sortedTasks count]) {
            style = UITableViewCellEditingStyleNone;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    
    return style;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.row == [self.sortedTasks count]) {
        NSInteger row = [self.sortedTasks count]-1;
        
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];     
    }
    
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the task array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
	
    NSInteger start = fromIndexPath.row;
    NSInteger end = toIndexPath.row;
    if(start == end)
        return;
    
    Task *task = [self.sortedTasks objectAtIndex:start];
    [self.sortedTasks removeObjectAtIndex:start];
    [self.sortedTasks insertObject:task atIndex:end];
    
	if (toIndexPath.row < start) {
		start = toIndexPath.row;
	}
	if (fromIndexPath.row > end) {
		end = fromIndexPath.row;
	}
    
    
	for (NSInteger i = start; i <= end; i++) {
		task = [self.sortedTasks objectAtIndex:i];
		task.sortIndex = [NSNumber numberWithInteger:i];
	}
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Task *selectedTask = [self.sortedTasks objectAtIndex:[indexPath row]];
        [[segue destinationViewController] setDetailItemUUID:selectedTask.uuid];
    }
}

#pragma mark - Data Updates

- (IBAction)competedSwitchChanged:(id)sender {
	Task *detailTask = (Task *)self.detailItem;

	if (0 == [self.completedSwitch selectedSegmentIndex]) {
		[detailTask setUncompletedAtDate:nil];
	}
    else if (1 == [self.completedSwitch selectedSegmentIndex]) {
		[detailTask setCompletedAtDate:nil partial:NO];
	}
}

- (IBAction)scheduledDateButtonPressed:(id)sender {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"WSScheduledDatePickerStoryboard" bundle:nil];
	WSDatePickerViewController *datePicker = [storyboard instantiateInitialViewController];
	datePicker.delegate = self;
	Task *task = (Task *)self.detailItem;
	
	WSDatePickerScheduledDate *scheduledDate = [[WSDatePickerScheduledDate alloc] init];
	scheduledDate.date = task.scheduledDate ? : [NSDate today];
	if (task.repeat) {
		scheduledDate.repeatFrequency = [task.repeat.frequency integerValue];
		scheduledDate.repeatEndAfterCount = [task.repeat.endAfterCount integerValue];
		scheduledDate.repeatEndAfterDate = task.repeat.endAfterDate;
	}
	else {
		scheduledDate.repeatFrequency = -1;
		scheduledDate.repeatEndAfterCount = 0;
		scheduledDate.repeatEndAfterDate = nil;
	}
	datePicker.scheduledDate = scheduledDate;
	
    [self.navigationController pushViewController:datePicker animated:YES];
}

- (void)datePickerControllerDidPickDate:(WSDatePickerScheduledDate *)scheduledDate {
    //schedule date for task
    if([self.detailItem isKindOfClass:[Task class]]) {
        Task *task = (Task*) self.detailItem;
		if ([task.scheduledDate isEqualToDate:[scheduledDate.date dateQuantizedToDay]]) {
			return;
		}
        if (!scheduledDate || !scheduledDate.date) {
            [task setScheduledDate:nil handlingRecurrenceAtDate:self.shownForDay];
        }
        else {
            [task setScheduledDate:[scheduledDate.date dateQuantizedToDay] handlingRecurrenceAtDate:self.shownForDay];
        }
    }
}

- (void)datePickerControllerDidChangeRepeatFrequency:(WSDatePickerScheduledDate *)scheduledDate {
	Task *task = (Task *) self.detailItem;

	if (-1 == scheduledDate.repeatFrequency) {
		task.repeat = nil;
	}
	else {
		if (nil == task.repeat) {
			task.repeat = [RecurrenceRule recurrenceRule];
			task.repeat.endAfterDate = nil;
			task.repeat.endAfterCount = @(3);
			scheduledDate.repeatEndAfterDate = nil;
			scheduledDate.repeatEndAfterCount = 3;
		}
		task.repeat.frequency = @(scheduledDate.repeatFrequency);
	}
}

- (void)datePickerControllerDidChangeEndAfterDateEndAfterCount:(WSDatePickerScheduledDate *)scheduledDate {
	Task *task = (Task *) self.detailItem;
	if (nil == task.repeat) {
		task.repeat = [RecurrenceRule recurrenceRule];
		task.repeat.frequency = DMRecurrenceFrequencyDaily;
		scheduledDate.repeatFrequency = DMRecurrenceFrequencyDaily;
	}
	task.repeat.endAfterDate = scheduledDate.repeatEndAfterDate;
	task.repeat.endAfterCount = @(scheduledDate.repeatEndAfterCount);
}

- (IBAction)projectColorButtonPressed:(id)sender {
	//put popover up to select date
	WSProjectColorPickerViewController *colorPicker = [[WSProjectColorPickerViewController alloc] init];
	colorPicker.color = [[self.detailItem valueForKey:@"displayAttributes"] valueForKey:@"nativeColor"];
	colorPicker.delegate = self;
	[colorPicker setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	[self presentViewController:colorPicker animated:YES completion:nil];
}

- (void)colorPickerController:(WSProjectColorPickerViewController *)controller didPickColor:(UIColor *)color {
	[[self.detailItem valueForKey:@"displayAttributes"] setValue:color forKey:@"nativeColor"];
	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nameEdited:(id)sender
{
	AbstractTask *detailItem = self.detailItem;
	[self.nameTextField resignFirstResponder];
	if (![detailItem.name isEqualToString:self.nameTextField.text] &&
		(self.nameTextField.text.length || detailItem.name.length)) {
		[detailItem setName:self.nameTextField.text];
	}
	self.navigationItem.title = [detailItem name];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.descriptionLabel.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	AbstractTask *detailItem = self.detailItem;
    //save details to item
	if (![detailItem.attributedDetailsAttributedString isEqualToAttributedString:self.detailTextView.attributedText] &&
		(self.detailTextView.attributedText.length || detailItem.attributedDetailsAttributedString.length)) {
		[detailItem setAttributedDetailsAttributedString:self.detailTextView.attributedText];
	}
	
    if(self.detailTextView.text.length == 0) {
        self.descriptionLabel.hidden = NO;
	}
    [textView resignFirstResponder];
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	[self nameEdited:nil];
}

- (IBAction)insertNewObject:(UIButton *)sender
{
    Task *task = [Task task];
	
	NSMutableSet *tasks = [self.detailItem mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
    [self.sortedTasks addObject:task];
    
    [self updateSortedProjects];
	[self.tableView reloadData];
    [self editTitleOfTask:task];
}

- (IBAction)moveTask:(id)sender {
    //push table views to select project or task to move task to.
    WSMovePickerTableViewController *movePickerView = [self.storyboard instantiateViewControllerWithIdentifier:@"MovePicker"];
    [movePickerView setTaskView:self];
    [self.navigationController pushViewController:movePickerView animated:YES];
}

- (void)moveToTask:(NSString*)moveToTaskUUID
{
    AbstractTask *newParentTask = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:moveToTaskUUID];
    [self.detailItem.parent removeChildrenObject:self.detailItem];
    [newParentTask addChildrenObject:self.detailItem];
}

- (void)hideKeyboard:(id)sender
{
    [sender resignFirstResponder];
}

-(void)hideKeyboard
{
    [self.nameTextField resignFirstResponder];
    [self.detailTextView resignFirstResponder];
}


@end
