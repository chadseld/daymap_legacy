//
//  MainWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 4/11/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "MainWindowController.h"
#import "DayMapAppDelegate.h"
#import "DayMap.h"
#import "Project.h"
#import "AbstractTask+Additions.h"
#import "Task+Additions.h"
#import "Project+Additions.h"
#import "NSDate+WS.h"
#import "MiscUtils.h"
#import "DMCompletedFilterPopoverViewController.h"

@implementation MainWindowController {
    CalendarViewController *_calendarViewController;
    ProjectsViewController *_projectsViewController;
	CGFloat _lastSplitViewPosition;
	NSArray *_searchResultsLayoutConstraints;
}

- (void)dealloc
{
    _calendarViewController = nil;
    _projectsViewController = nil;
}

- (void)loadViews
{
	_projectsViewController = [[ProjectsViewController alloc] init];
    [_projectsViewController.view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_projectsViewController.view setFrame:self.splitTopView.bounds];
	[self.splitView replaceSubview:self.splitTopView with:_projectsViewController.view];
//    [self.splitTopView addSubview:_projectsViewController.view]; // we don't replace view here. We want to use a bordered backing view

    _calendarViewController = [[CalendarViewController alloc] init];
    [_calendarViewController.view setFrameSize:self.splitBottomView.frame.size];
    [self.splitView replaceSubview:self.splitBottomView with:_calendarViewController.view];
//	[self.splitBottomView addSubview:_calendarViewController.view];
}

//- (void)unloadViews
//{
//	[_projectsViewController.view removeFromSuperviewWithoutNeedingDisplay];
//	_projectsViewController = nil;
//	
//	[_calendarViewController.view removeFromSuperviewWithoutNeedingDisplay];
//	_calendarViewController = nil;
//}

- (void)awakeFromNib
{
    static BOOL __alreadyCalled = NO;
    assert(NO == __alreadyCalled);
    __alreadyCalled = YES;

	self.window.title = [[NSRunningApplication currentApplication] localizedName];

    // Load views
	[self loadViews];

	// Toolbar
	self.window.titlebarAppearsTransparent = YES;
	self.window.titleVisibility = NSWindowTitleHidden;
	[self.shareButton sendActionOn:NSLeftMouseDownMask];
	
	//Restore window size and position
	[self.window center];
	[self.window setFrameAutosaveName:@"mainWindow"];

    // Set autosave name only after modifying subviews, don't do this in XIB
    [self.splitView setAutosaveName:@"mainSplitView"];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
	if ([self searchResultsVisible]) {
		[self hideSearchResults];
		[self showSearchResults];
	}
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
	if ([self searchResultsVisible]) {
		[self hideSearchResults];
		[self showSearchResults];
	}
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [(DayMapAppDelegate *)[NSApp delegate] undoManager];
}

- (IBAction)addTask:(id)sender
{
	Task *task = [Task task];
	
	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;
	
	NSMutableSet *tasks = [DMCurrentManagedObjectContext.dayMap.inbox mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : task.uuid}];
	});
}

- (IBAction)addProject:(id)sender 
{
	[self showWindow:self];
	[self.window makeKeyAndOrderFront:self];
	[self.window makeMainWindow];

	[_projectsViewController addProject:sender];
}

- (IBAction)completedSliderChanged:(id)sender 
{
	DMCompletedFilterPopoverViewController *popoverController = [DMCompletedFilterPopoverViewController sharedController];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:popoverController selector:@selector(hide) object:nil];
	[popoverController performSelector:@selector(hide) withObject:nil afterDelay:1.0];
	
	[popoverController showFromView:sender];
	
	[(DayMapAppDelegate *)[NSApp delegate] willChangeValueForKey:@"completedDateFilter"];
	[(DayMapAppDelegate *)[NSApp delegate] didChangeValueForKey:@"completedDateFilter"];
}

- (IBAction)forwardDateRange:(id)sender {
	[_calendarViewController forwardDateRange:sender];
}

- (IBAction)backDateRange:(id)sender {
	[_calendarViewController backDateRange:sender];
}

- (IBAction)showWeek:(id)sender {
	[_calendarViewController setCalendarViewByMode:DMCalendarViewByWeek];
}

- (IBAction)showMonth:(id)sender {
	[_calendarViewController setCalendarViewByMode:DMCalendarViewByMonth];
}

- (IBAction)showHideCalendar:(id)sender {
	if ([_calendarViewController.view isHidden]) {
		[_calendarViewController.view setHidden:NO];
		[self.splitView setPosition:_lastSplitViewPosition ofDividerAtIndex:0];
	}
	else {
		[_projectsViewController.view setHidden:NO];
		[_calendarViewController.view setHidden:YES];
	}
	[self.splitView adjustSubviews];
}

- (IBAction)goToToday:(id)sender {
	[_calendarViewController showToday:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (@selector(showWeek:) == menuItem.action) {
		menuItem.state = _calendarViewController.calendarViewByMode == DMCalendarViewByWeek ? NSOnState : NSOffState;
	}
	else if (@selector(showMonth:) == menuItem.action) {
		menuItem.state = _calendarViewController.calendarViewByMode == DMCalendarViewByMonth ? NSOnState : NSOffState;
	}
	else if (@selector(goToToday:) == menuItem.action) {
		if ([_calendarViewController.week isEqualToDate:[[NSDate today] beginningOfWeek]]) {
			return NO;
		}
	}
	else if (@selector(showHideCalendar:) == menuItem.action) {
		if ([self.splitView isSubviewCollapsed:_calendarViewController.view]) {
			menuItem.title = NSLocalizedString(@"Show Calendar View", @"menu item");
		}
		else {
			menuItem.title = NSLocalizedString(@"Hide Calendar View", @"menu item");
		}
	}
	return YES;
}

- (IBAction)upgradeToFullVersion:(id)sender {
#ifdef TARGET_DAYMAP_LITE
	[((DayMapAppDelegate *)[NSApp delegate]) showUpgradeFromLiteNudgeWithReason:DMUpgradeNudgeReasonOther];
#endif
}

#pragma mark - Toolbar Delegate

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
#ifdef TARGET_DAYMAP_LITE
	return @[@"NewTask", @"NewProject", @"NSToolbarFlexibleSpaceItem", @"Share", @"HideCompleted", @"Search", @"Upgrade"];
#else
	return @[@"NewTask", @"NewProject", @"NSToolbarFlexibleSpaceItem", @"Share", @"HideCompleted", @"Search"];
#endif
	
}

#pragma mark - Sharing

- (IBAction)shareButtonClicked:(id)sender {
	NSString *shareItemString = @"";
	if ([(DayMapAppDelegate *)[NSApp delegate] selectedProject]) {
		Project *project = (Project *)[DMCurrentManagedObjectContext objectWithUUID:[(DayMapAppDelegate *)[NSApp delegate] selectedProject]];
		shareItemString = [project utf8FormattedString];
	}
	else {
		NSSet *selection = [(DayMapAppDelegate *)[NSApp delegate] selectedTasks];
		NSMutableSet *tasksSet = [NSMutableSet new];
		for (Task *task in [DMCurrentManagedObjectContext objectsWithUUIDs:selection]) {
			[tasksSet addObject:task];
			NSArray *breadcrumbs = [task breadcrumbs];
			for (NSInteger i = 1; i < breadcrumbs.count; i++) { // skip first item because it is a Project not a Task
				[tasksSet addObject:breadcrumbs[i]];
			}
		}
		
		// sort to root nodes
		NSSortDescriptor *rootDepthSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"breadcrumbs" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
			NSArray *array1 = (NSArray*)obj1;
			NSArray *array2 = (NSArray*)obj2;
			if (array1.count < array2.count) {
				return NSOrderedAscending;
			}
			else if (array1.count > array2.count) {
				return NSOrderedDescending;
			}
			else {
				return NSOrderedSame;
			}
		}];
		NSSortDescriptor *sortIndexSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES];
		NSArray *tasks = [tasksSet sortedArrayUsingDescriptors:@[rootDepthSortDescriptor, sortIndexSortDescriptor]];
		
		shareItemString = [Task utf8FormattedStringForTasks:tasks];
		shareItemString = [shareItemString stringByReplacingOccurrencesOfString:@"\t" withString:@"    "]; // need spaces for iMessage since it drops tabs
	}
	
	if (!shareItemString) return;

//	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
//	NSString *airDropPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"DayMap"];
//	airDropPath = [airDropPath stringByAppendingPathComponent:[NSString stringWithFormat:@"DayMap Airdrop %@.txt", [dateFormatter stringFromDate:[NSDate date]]]];
//	NSURL *airDropURL = [NSURL fileURLWithPath:airDropPath];
//	NSError *deleteError = nil;
//	[[NSFileManager defaultManager] removeItemAtPath:airDropPath error:&deleteError];
//	NSError *writeError = nil;
//	[[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:[airDropPath stringByDeletingLastPathComponent]] withIntermediateDirectories:YES attributes:nil error:&writeError];
//	[shareItemString writeToURL:airDropURL atomically:YES encoding:NSUTF8StringEncoding error:&writeError];

	NSSharingServicePicker *picker = [[NSSharingServicePicker alloc] initWithItems:@[shareItemString, /*airDropURL*/]];
	picker.delegate = self;
	
	[picker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices {
	
	// Scrap the proposed services and provide our own
	NSMutableArray *services = [NSMutableArray new];
	if ([[items firstObject] isEqualToString:@""]) {
		return services;
	}
	
	[services addObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail]];
	[services addObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameComposeMessage]];
//	[services addObject:[NSSharingService sharingServiceNamed:NSSharingServiceNameSendViaAirDrop]];
	[services addObject:[[NSSharingService alloc] initWithTitle:NSLocalizedString(@"Copy", @"sharing service menu")
														  image:[NSImage imageNamed:@"copyMenu"]
												 alternateImage:nil
														handler:^{
															[[NSPasteboard generalPasteboard] declareTypes:@[ NSPasteboardTypeString, @"public.utf8-plain-text" ] owner:self];
															[[NSPasteboard generalPasteboard] setString:[items firstObject] forType:NSPasteboardTypeString];
															[[NSPasteboard generalPasteboard] setString:[items firstObject] forType:@"public.utf8-plain-text"];
														}]];
	if ([(DayMapAppDelegate *)[NSApp delegate] selectedProject]) {
		[services addObject:[[NSSharingService alloc] initWithTitle:NSLocalizedString(@"Print", @"sharing service menu")
															  image:[NSImage imageNamed:@"printMenu"]
													 alternateImage:nil
															handler:^{
																[(DayMapAppDelegate *)[NSApp delegate] printSelectedProjects:nil];
															}]];
	}

	return services;
}

- (id<NSSharingServiceDelegate>)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker delegateForSharingService:(NSSharingService *)sharingService {
	return self;
}

#pragma mark - Search

- (IBAction)searchFieldChanged:(id)sender
{
	if (self.searchField.stringValue.length == 0 && [self searchResultsVisible]) {
		[self hideSearchResults];
		self.searchController.searchString = nil;
		return;
	}
	
	if (self.searchField.stringValue.length > 0 && ![self searchResultsVisible]) {
		[self showSearchResults];
	}

	self.searchController.searchString = self.searchField.stringValue;
}

- (BOOL)searchResultsVisible
{
	return ([self.searchController.searchResultsTableView enclosingScrollView].superview != nil);
}

- (void)showSearchResults
{
	[self.searchController.searchResultsTableView enclosingScrollView].translatesAutoresizingMaskIntoConstraints = NO;
	[self.window.contentView addSubview:[self.searchController.searchResultsTableView enclosingScrollView]];
	
	_searchResultsLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[splitView]-0-[searchView(250)]-0-|" options:0 metrics:nil views:@{@"splitView" : self.splitView, @"searchView" : [self.searchController.searchResultsTableView enclosingScrollView]}];
	_searchResultsLayoutConstraints = [_searchResultsLayoutConstraints arrayByAddingObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[searchView]-0-|" options:0 metrics:nil views:@{@"searchView" : [self.searchController.searchResultsTableView enclosingScrollView]}]];

	[self.window.contentView addConstraints:_searchResultsLayoutConstraints];
}

- (void)hideSearchResults
{
	[self.window.contentView removeConstraints:_searchResultsLayoutConstraints];
	[[self.searchController.searchResultsTableView enclosingScrollView] removeFromSuperview];
}

- (void)performFindPanelAction:(id)sender
{
    [self selectSearchField:sender];
}

- (IBAction)selectSearchField:(id)sender
{
	if([self.searchField acceptsFirstResponder]) [self.window makeFirstResponder:self.searchField];
}

#pragma mark - Split View

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	if ([_calendarViewController.view isHidden] || [_projectsViewController.view isHidden]) {
		return;
	}
	_lastSplitViewPosition = _projectsViewController.view.frame.size.height;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
	return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {

	if (_projectsViewController.view.frame.size.height < _calendarViewController.view.frame.size.height && subview == _projectsViewController.view) {
		return YES;
	}
	if (_projectsViewController.view.frame.size.height >= _calendarViewController.view.frame.size.height && subview == _calendarViewController.view) {
		return YES;
	}
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	return 80;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    return self.splitView.frame.size.height - 215;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return floor(proposedPosition);
}

@end
