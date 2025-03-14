//
//  WSWeekViewController.m
//  DayMap
//
//  Created by Jonathan Huggins on 6/4/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//
//  Sections display each day's task for the current week
//  Section headers are just like today view table header
//  Would be nice to drag between days to reschedule, involves edit commit changes

#import <QuartzCore/QuartzCore.h>
#import "WSWeekViewController.h"
#import "WSRichTextTableViewCell.h"
#import "WSDetailViewController.h"
#import "NSDate+WS.h"
#import "Task+Additions.h"
#import "WSAppDelegate.h"
#import "MiscUtils.h"
#import "DayMap.h"
#import "Project.h"


@interface WSWeekViewController ()
@property (nonatomic, strong) NSDate *week;
@end

@implementation WSWeekViewController

- (void)setWeek:(NSDate *)week {
	_week = [week dateQuantizedToDay];
	
    [self.navigationItem setTitle:NSLocalizedString(@"Week", @"relative week")];
    
	[self setNeedsUpdateWeekTasks];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Week";
    self.tableView.tableHeaderView = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.week = [NSDate today];
    [self setNeedsUpdateWeekTasks];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.dayTasks objectAtIndex:section] count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"EditableCell";
    WSRichTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
	Task *task = [[self.dayTasks objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
	cell.shouldItalicize = NO; // don't show italic text in the calendar views
	cell.day = [self.week dateByAddingDays:[indexPath section]];
    cell.task = task;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kSectionHeaderHeight;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSDateComponents *oneDay = [[NSDateComponents alloc] init];
    oneDay.day = section;
    NSDate *headerDay = [self.currentCalendar dateByAddingComponents:oneDay toDate:self.week options:0];
    UIView *headerView = [self headerViewForDate:headerDay];
        
    return headerView;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	Task *task = [[self.dayTasks objectAtIndex:[sourceIndexPath section]] objectAtIndex:[sourceIndexPath row]];
    [[self.dayTasks objectAtIndex:[sourceIndexPath section]] removeObjectAtIndex:[sourceIndexPath row]];
    [[self.dayTasks objectAtIndex:[destinationIndexPath section]] insertObject:task atIndex:[destinationIndexPath row]];

    NSDateComponents *oneDay = [[NSDateComponents alloc] init];
    oneDay.day = [destinationIndexPath section];
    NSDate *headerDay = [self.currentCalendar dateByAddingComponents:oneDay toDate:self.week options:0];
    task.scheduledDate = headerDay;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Task *task = [[self.dayTasks objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];

		NSDateComponents *oneDay = [[NSDateComponents alloc] init];
		oneDay.day = [indexPath section];
		NSDate *headerDay = [self.currentCalendar dateByAddingComponents:oneDay toDate:self.week options:0];

		[task setScheduledDate:nil handlingRecurrenceAtDate:headerDay];
        [self updateWeekTasks];
    }
}

- (void)insertNewObject
{
    Task *task = [Task task];
	
	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
    
    [task setSortIndexInDay:[NSNumber numberWithInteger:[self.dayTasks[0] count]]];

    [task setScheduledDate:[NSDate today]];
    
    [self updateWeekTasks];
    
    [self editTitleOfTask:task];
}

- (UITableViewCell *)cellForTask:(AbstractTask *)task {
    for (NSInteger section = 0; section < 7; section++) {
        NSInteger row = [self.dayTasks[section] indexOfObject:task];
        if (NSNotFound == row) {
            continue;
        }

        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        return cell;
    }
    return nil;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Task *selectedObject = [[self.dayTasks objectAtIndex:[indexPath section]] objectAtIndex:[indexPath row]];
        [[segue destinationViewController] setDetailItemUUID:selectedObject.uuid];

		[[segue destinationViewController] setShownForDay:[self.week dateByAddingDays:[indexPath section]]];
    }
}

#pragma mark - Week Task updates

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

- (void)updateSortedProjects {
    self.sortedTasks = nil;
    [self setNeedsUpdateWeekTasks];
}

- (void)setNeedsUpdateWeekTasks
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateWeekTasks) object:nil];
	[self performSelector:@selector(updateWeekTasks) withObject:nil afterDelay:0.0];
}

- (void)updateWeekTasks
{
	NSDate *weekStart = [NSDate today];
	
	self.dayTasks = [[NSMutableArray alloc] initWithCapacity:7];
	
	//add section number of days to the week start day
	for (NSInteger i = 0; i<7; i++) {
		NSDate *day = [weekStart dateByAddingDays:i];
		NSArray *sortedTasks = [(WSAppDelegate *)[NSApp delegate] tasksForDay:day];
		sortedTasks = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:sortedTasks], [(WSAppDelegate *)[NSApp delegate] completedDateFilter], day, nil);
		sortedTasks = [self sortTasks:sortedTasks forDay:day];
		[self.dayTasks addObject:[sortedTasks mutableCopy]];
	}
	
	[self.tableView reloadData];
}

#pragma mark - Handle gestures

- (void)handleGesture:(UISwipeGestureRecognizer *)sender
{
    if (UISwipeGestureRecognizerDirectionRight == sender.direction) {
        //swipe right, change day and animate to new view
        //subtract 1 day from today's date
		self.week = [self.week dateByAddingWeeks:-1];
    }
    if (UISwipeGestureRecognizerDirectionLeft == sender.direction) {
        //swipe left, change day and animate to new view
        //add 1 day to today's date
		self.week = [self.week dateByAddingWeeks:1];
		
    }
}
@end
