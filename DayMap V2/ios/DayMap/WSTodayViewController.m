//
//  WSTodayViewController.m
//  DayMap
//
//  Created by Jonathan Huggins on 4/3/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSTodayViewController.h"
#import "DayMap.h"
#import "Task+Additions.h"
#import "Project.h"
#import "WSDetailViewController.h"
#import "NSDate+WS.h"
#import "WSRichTextTableViewCell.h"
#import "MiscUtils.h"
#import "WSAppDelegate.h"

@interface WSTodayViewController ()
@property (nonatomic, strong) NSDateFormatter *dayHeaderFormatter;
@end

@implementation WSTodayViewController

- (void)tasksNeedUpdate:(NSNotification *)notification {
    if (self.editingTask == nil) {
        [self updateSortedProjects];
        [self.tableView reloadData];
    }
}

- (NSArray *)sortTasks:(NSArray *)tasks {
	// Pre-load sort indexes to avoid speed impact of so many core data fetches
	NSMutableArray *sortIndexes = [[NSMutableArray alloc] initWithCapacity:tasks.count];
	for (Task *task in tasks) {
		[sortIndexes addObject:@([task sortIndexInDayForDate:self.today])];
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

- (void)updateSortedProjects
{
	NSSet *tasks = [NSSet setWithArray:[(WSAppDelegate *)[NSApp delegate] tasksForDay:self.today]];
	NSArray *sortedTasks = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(tasks, [(WSAppDelegate *)[NSApp delegate] completedDateFilter], self.today, nil);
	self.sortedTasks = [[self sortTasks:sortedTasks] mutableCopy];
}

- (void)setToday:(NSDate *)today {
	_today = [today dateQuantizedToDay];
	
	if ([_today isEqualToDate:[NSDate today]]) {
		[self.navigationItem setTitle:NSLocalizedString(@"Today", @"relative date")];
	}
	else {
		NSDateComponents *components = [_currentCalendar components:NSCalendarUnitDay
											  fromDate:[NSDate today]
												toDate:_today options:0];
		NSInteger days = [components day];
		if (days > 0) {
			[self.navigationItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Today +%d", @"relative date"), days]];
		}
		if (days < 0) {
			[self.navigationItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Today %d", @"relative date"), days]];
		}
	}
    
    UILabel *dateLabel = (UILabel*)[[self.tableHeaderView subviews] objectAtIndex:0];
    dateLabel.text = [_dayHeaderFormatter stringFromDate:self.today];

	[self updateSortedProjects];
	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tasksNeedUpdate:) name:DMUpdateWeekViewNotification object:nil];

	self.today = [NSDate today];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
	self.navigationItem.rightBarButtonItem = addButton;
    
    _currentCalendar = [NSCalendar currentCalendar];
	_currentCalendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    _dayHeaderFormatter = [[NSDateFormatter alloc] init];
    [_dayHeaderFormatter setLocale:[_currentCalendar locale]];
	_dayHeaderFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSString *localizedDateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEE, MMMM dd" options:0 locale:[_currentCalendar locale]];
    [_dayHeaderFormatter setDateFormat:localizedDateFormat];
    
    // Create and set the table header view.
    if (self.tableHeaderView == nil) {
        self.tableHeaderView = [self headerViewForDate:self.today];
        self.tableView.tableHeaderView = self.tableHeaderView;
        self.tableView.allowsSelectionDuringEditing = YES;
        
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
		swipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.tableHeaderView addGestureRecognizer:swipe];
		swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
		swipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.tableHeaderView addGestureRecognizer:swipe];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:DMUpdateWeekViewNotification object:nil];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.today = [NSDate today];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        [[segue destinationViewController] setShownForDay:self.today];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.sortedTasks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EditableCell";
    WSRichTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    // Configure the cell...
	Task *task = [self.sortedTasks objectAtIndex:[indexPath row]];
	cell.shouldItalicize = NO; // don't show italic text in the calendar views
	cell.day = self.today;
    cell.task = task;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canMove = YES;
    
//    canMove = indexPath.row != [self.sortedTasks count];
    
    return canMove;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the task array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
    Task *task = [self.sortedTasks objectAtIndex:fromIndexPath.row];
    [self.sortedTasks removeObjectAtIndex:fromIndexPath.row];
    [self.sortedTasks insertObject:task atIndex:toIndexPath.row];
	
	NSInteger start = fromIndexPath.row;
	if (toIndexPath.row < start) {
		start = toIndexPath.row;
	}
	NSInteger end = toIndexPath.row;
	if (fromIndexPath.row > end) {
		end = fromIndexPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		task = [self.sortedTasks objectAtIndex:i];
		[task setSortIndexInDay:[NSNumber numberWithInteger:i] forDate:self.today];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
		Task *task = [self.sortedTasks objectAtIndex:[indexPath row]];
		[task setScheduledDate:nil handlingRecurrenceAtDate:self.today];
        [self.sortedTasks removeObject:task];
        [self.tableView reloadData];
    }   
}

#pragma mark - Table view delegate

- (void)insertNewObject
{
    Task *task = [Task task];
	
	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];

    [task setSortIndexInDay:[NSNumber numberWithInteger:[self.sortedTasks count]]];
    
    [task setScheduledDate:self.today];

    [self updateSortedProjects];
    [self.tableView reloadData];
    [self editTitleOfTask:task];
}

#pragma mark - Swipe gesture recogniser handler

- (void)handleGesture:(UISwipeGestureRecognizer *)sender
{
    if (UISwipeGestureRecognizerDirectionRight == sender.direction) {
        //swipe right, change day and animate to new view
        //subtract 1 day from today's date
		self.today = [self.today dateByAddingDays:-1];
    }
    if (UISwipeGestureRecognizerDirectionLeft == sender.direction) {
        //swipe left, change day and animate to new view
        //add 1 day to today's date
		self.today = [self.today dateByAddingDays:1];
		
    }
}

#pragma mark - Section/Table header generation
-(UIView *)headerViewForDate:(NSDate *)day
{
    CGFloat viewWidth = self.tableView.frame.size.width;
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, viewWidth, kSectionHeaderHeight)];
    UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, viewWidth, kSectionHeaderHeight)];
    headerLabel.text = [_dayHeaderFormatter stringFromDate:day];
    headerLabel.font = [UIFont systemFontOfSize:24];
    [headerLabel setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.backgroundColor = [UIColor dayMapCurrentDayBackgroundColor];
    UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, kSectionHeaderHeight-1, self.tableView.frame.size.width, 1)];
    lineView.backgroundColor = [UIColor dayMapDividerColor];
    [lineView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin];
    [headerView addSubview:headerLabel];
    [headerView addSubview:lineView];
    
    return headerView;
}

@end
