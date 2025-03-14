//
//  WSAbstractTaskTableViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 5/12/12.
//  Copyright (c) 2012 Monk Software LLC. All rights reserved.
//

#import "WSAbstractTaskTableViewController.h"
#import "WSDetailViewController.h"
#import "WSRichTextTableViewCell.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"


@interface WSAbstractTaskTableViewController () {
	__weak id _observedObject;
    BOOL setInsets;
	UIEdgeInsets defaultContentInsets;
}

@end


@implementation WSAbstractTaskTableViewController

#pragma mark - View Lifecycle

- (void)updateSortedProjects {
	// Subclass to implement
}

- (NSManagedObject *)objectToObserve {
	// Subclass to implement
	return nil;
}

- (NSArray *)keyPathsToObserve {
	// Subclass to implement
	return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([[self keyPathsToObserve] containsObject:keyPath]) {
			[self updateSortedProjects];
			[self.tableView reloadData];
		}
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)childrenDidChangeForParentNotification:(NSNotification *)notification {
    AbstractTask *task = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:[notification object]];
    AbstractTask *root = [(AbstractTask *)task rootProject];

    // If this project view is displaying this changed object, update.
    if ([[root uuid] isEqual:[[self objectToObserve] valueForKey:@"uuid"]]) {
		[self updateSortedProjects];
		[self.tableView reloadData];
    }
}

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification {
	for (NSString *keyPath in [self keyPathsToObserve]) {
		[_observedObject removeObserver:self forKeyPath:keyPath context:(__bridge void*)self];
	}

	self.sortedTasks = nil;
}

- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	[self updateSortedProjects];

	for (NSString *keyPath in [self keyPathsToObserve]) {
		[[self objectToObserve] addObserver:self forKeyPath:keyPath options:0 context:(__bridge void*)self];
	}
	_observedObject = [self objectToObserve];

	[self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeManagedObjectContextNotification:) name:DMWillChangeManagedObjectContext object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeManagedObjectContextNotification:) name:DMDidChangeManagedObjectContext object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingResigned:) name:WSRichTextTableViewCellResignedObserverNotification object:nil];

	// Do any additional setup after loading the view, typically from a nib.
    //self.detailViewController = (WSDetailViewController *)[[self.tabBarController.splitViewController.viewControllers lastObject] topViewController];
	
	// Set up the edit and add buttons.
    setInsets = true;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
	self.navigationItem.rightBarButtonItem = addButton;
    self.tableView.separatorColor = [UIColor dayMapDividerColor];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	[self updateSortedProjects];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

    if (setInsets) {
        defaultContentInsets = self.tableView.contentInset;
        setInsets = false;
    }

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
	NSDictionary* info = [aNotification userInfo];
	CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
 
    UIEdgeInsets contentInsets = defaultContentInsets;
    contentInsets.bottom = kbSize.height;
	self.tableView.contentInset = contentInsets;
	self.tableView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	self.tableView.contentInset = defaultContentInsets;
	self.tableView.scrollIndicatorInsets = defaultContentInsets;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
}
#pragma mark - Data updates

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation == UIInterfaceOrientationPortrait);
	} else {
	    return YES;
	}
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

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
	cell.shouldItalicize = YES;
    cell.task = task;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	cell.backgroundColor = (indexPath.row % 2) ? [UIColor dayMapCurrentDayBackgroundColor] : [UIColor dayMapBackgroundColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
}


#pragma mark - UITableView delegate

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canMove = NO;
    canMove = indexPath.row != [self.sortedTasks count];
    
    return canMove;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        AbstractTask *selectedObject = [self.sortedTasks objectAtIndex:[indexPath row]];
        [[segue destinationViewController] setDetailItemUUID:selectedObject.uuid];
		[[segue destinationViewController] setShownForDay:nil];
    }
}

#pragma mark - Abstract Task methods

- (void)pushDetailViewForAbstractTask:(AbstractTask *)task
{
    //push detail item created
    WSDetailViewController *detailItemView = [self.storyboard instantiateViewControllerWithIdentifier:@"detailView"];
    [detailItemView setDetailItemUUID:task.uuid];
    detailItemView.shownForDay = nil;
    [detailItemView.nameTextField becomeFirstResponder];
    [self.navigationController pushViewController:detailItemView animated:YES];
}

- (UITableViewCell *)cellForTask:(AbstractTask *)task {
    NSInteger index = [self.sortedTasks indexOfObject:task];
    if (NSNotFound == index) {
        return nil;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    return cell;
}

- (void)editTitleOfTask:(AbstractTask *)task {
    UITableViewCell *cell = [self cellForTask:task];
    if (cell && [cell respondsToSelector:@selector(editTitle)]) {
        [cell performSelector:@selector(editTitle)];
        self.editingTask = task;
    }
}

- (void)insertNewObject {
    
}

#pragma mark - Resign Notifications

- (void)editingResigned:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *objectID = userInfo[@"taskID"];
    if ([[self.editingTask uuid] isEqual:objectID]) {
        self.editingTask = nil;
    }
}

@end
