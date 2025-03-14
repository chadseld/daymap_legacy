//
//  MovePickerTableViewController.m
//  DayMap
//
//  Created by Jonathan Huggins on 5/21/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSMovePickerTableViewController.h"
#import "DayMap.h"
#import "Project.h"
#import "DayMapManagedObjectContext.h"
#import "MiscUtils.h"
#import "WSRichTextTableViewCell.h"

@interface WSMovePickerTableViewController ()
@property (strong, nonatomic) AbstractTask *detailItem;

@end

@implementation WSMovePickerTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    
    UIBarButtonItem *pickButton = [[UIBarButtonItem alloc] initWithTitle:@"Move Here" style:UIBarButtonItemStylePlain target:self action:@selector(pick)];
	self.navigationItem.rightBarButtonItem = pickButton;    

	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.detailItem) {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

#pragma mark - Update data

- (void)updateSortedProjects {
    if(self.detailItem){
        self.navigationItem.title = self.detailItem.name;
        self.sortedTasks = [[[self.detailItem.children allObjects] sortedArrayUsingDescriptors:SORT_BY_SORTINDEX] mutableCopy];
    }
    else {
        self.navigationItem.title = @"Projects";
		NSSet *projects = DMCurrentManagedObjectContext.dayMap.projects;
		projects = [projects setByAddingObject:DMCurrentManagedObjectContext.dayMap.inbox];
		if ([DMCurrentManagedObjectContext.dayMap.inbox.sortIndex integerValue] != -1) DMCurrentManagedObjectContext.dayMap.inbox.sortIndex = @(-1);
		NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
		self.sortedTasks = [sortedProjects mutableCopy];
    }
}

- (void)setDetailItemUUID:(NSString *)detailItemUUID
{
	_detailItemUUID = detailItemUUID;
	self.detailItem = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:_detailItemUUID];
	
    [self updateSortedProjects];
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"PushSubtask"]) {
        if ([sender isKindOfClass:[WSRichTextTableViewCell class]]) {
            WSRichTextTableViewCell *cell = (WSRichTextTableViewCell *)sender;
            [[segue destinationViewController] setDetailItemUUID:cell.task.uuid];
        }
        [[segue destinationViewController] setTaskView:self.taskView];
    }
}

#pragma mark - Picked Move

- (void)pick
{
    [self.taskView moveToTask:self.detailItemUUID];
    [self.navigationController popToViewController:self.taskView animated:YES];
}
@end
