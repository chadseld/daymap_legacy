//
//  WSMasterViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/24/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSProjectViewController.h"
#import "WSDetailViewController.h"
#import "DayMap.h"
#import "Project+Additions.h"
#import "MiscUtils.h"
#import "WSProjectTableViewCell.h"
#import "ProjectDisplayAttributes+Additions.h"
#import <QuartzCore/QuartzCore.h>

@interface WSProjectViewController ()
@end

@implementation WSProjectViewController

- (void)updateSortedProjects {
	NSArray *sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES]];
	self.sortedTasks = [[[DMCurrentManagedObjectContext.dayMap.projects allObjects] sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
}

- (NSManagedObject *)objectToObserve {
	return DMCurrentManagedObjectContext.dayMap;
}

- (NSArray *)keyPathsToObserve {
	return @[@"projects"];
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        Project* deleteProject = [self.sortedTasks objectAtIndex:[indexPath row]];
        [DMCurrentManagedObjectContext deleteObject:deleteProject];
        [self.sortedTasks removeObject:deleteProject];
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [tableView endUpdates];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    WSProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	Project *project = [self.sortedTasks objectAtIndex:[indexPath row]];
	cell.project = project;
    
    return cell;
}

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

#pragma mark - Actions

- (void)insertNewObject
{
    Project *project = [Project project];
	
    NSManagedObject *displayAttrs = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"ProjectDisplayAttributes"
                                     inManagedObjectContext:DMCurrentManagedObjectContext];
	[displayAttrs setValue:WSCreateUUID() forKey:@"uuid"];
	[(ProjectDisplayAttributes *)displayAttrs setNativeColor:[UIColor randomProjectColor]];
	[project setValue:displayAttrs forKey:@"displayAttributes"];
    
    NSMutableSet *projects = [DMCurrentManagedObjectContext.dayMap mutableSetValueForKey:@"projects"];
	NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	project.sortIndex = [NSNumber numberWithInteger:[[[sortedProjects lastObject] sortIndex] integerValue] + 1];
    [projects addObject:project];

    // Create a new instance of the entity managed by the fetched results controller.
    // If appropriate, configure the new managed object.
//    Project *newChild = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:DMCurrentManagedObjectContext];
//	newChild.uuid = WSCreateUUID();
//	ProjectDisplayAttributes *displayAttrs = [NSEntityDescription
//                                     insertNewObjectForEntityForName:@"ProjectDisplayAttributes" 
//                                     inManagedObjectContext:DMCurrentManagedObjectContext];
////	[displayAttrs setValue:WSCreateUUID() forKey:@"uuid"];
//    [displayAttrs setUuid:WSCreateUUID()];
//    [displayAttrs setNativeColor:[UIColor blueColor]];
//	[newChild setValue:displayAttrs forKey:@"displayAttributes"];
//    [newChild setName:@"Untitled Project"];
//    [newChild setCreatedDate:[NSDate date]];
//    [newChild setSortIndex:[NSNumber numberWithInteger:[self.sortedTasks count]]];
    
//    [DMCurrentManagedObjectContext.dayMap addProjectsObject:newChild];
    [self.sortedTasks addObject:project];
    
    [self.tableView reloadData];
    
    [self pushDetailViewForAbstractTask:project];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
