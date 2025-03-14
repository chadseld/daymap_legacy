//
//  WSInboxViewController.m
//  DayMap
//
//  Created by Jonathan Huggins on 2/29/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSInboxViewController.h"
#import "WSDetailViewController.h"
#import "DayMap.h"
#import "Project.h"
#import "Task+Additions.h"
#import "MiscUtils.h"
#import "WSAppDelegate.h"

@interface WSInboxViewController ()

@end

@implementation WSInboxViewController


#pragma mark - Data updates

- (void)updateSortedProjects {
    NSSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox children];
    self.sortedTasks = [WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(tasks, [(WSAppDelegate *)[NSApp delegate] completedDateFilter], nil, SORT_BY_SORTINDEX) mutableCopy];
}

- (NSManagedObject *)objectToObserve {
	return DMCurrentManagedObjectContext.dayMap.inbox;
}

- (NSArray *)keyPathsToObserve {
	return @[@"children"];
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        [DMCurrentManagedObjectContext deleteObject:[self.sortedTasks objectAtIndex:[indexPath row]]];
        [self.sortedTasks removeObjectAtIndex:[indexPath row]];
        [self.tableView reloadData];
    }
}

//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return YES;
//}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the task array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
    AbstractTask *task = [self.sortedTasks objectAtIndex:fromIndexPath.row];
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
		task.sortIndex = [NSNumber numberWithInteger:i];
	}
}

- (void)insertNewObject
{
    Task *task = [Task task];
	
	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
    
    [self updateSortedProjects];
	[self.tableView reloadData];
    [self editTitleOfTask:task];
}

@end
