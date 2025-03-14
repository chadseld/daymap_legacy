//
//  ProjectViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/21/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectsViewController.h"
#import "DayMapAppDelegate.h"
#import "DayMap.h"
#import "ProjectTableHeaderCell.h"
#import "ProjectEditPopoverViewController.h"
#import "Project+Additions.h"
#import "MiscUtils.h"
#import "ProjectDisplayAttributes+Additions.h"
#import "AbstractTask.h"
#import "AbstractTask+Additions.h"
#import "NSColor+WS.h"
#import "ProjectTableRowView.h"
#import "NSMenu+WS.h"
#import "Task+Additions.h"

@implementation ProjectsViewController {
    NSMutableSet *_observingHeaderValuesOfProjects;
}

- (id)init
{
    self = [super initWithNibName:@"ProjectsView" bundle:nil];
    if (self) {
        // Initialization code here.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeTaskVisibleNotification:) name:DMMakeTaskVisibleNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeManagedObjectContextNotification:) name:DMWillChangeManagedObjectContext object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeManagedObjectContextNotification:) name:DMDidChangeManagedObjectContext object:nil];
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (Project *project in [self sortedProjects]) {
        NSString *identifier = project.uuid;
        if([_observingHeaderValuesOfProjects member:identifier]) {
            [project removeObserver:self forKeyPath:@"displayAttributes.color" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [project removeObserver:self forKeyPath:@"archived" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [project removeObserver:self forKeyPath:@"name" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [_observingHeaderValuesOfProjects removeObject:identifier];
        }
    }
	    
	[DMCurrentManagedObjectContext removeObserver:self forKeyPath:@"dayMap.projects" context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedProject" context:(__bridge void*)self];
	[self.view removeObserver:self forKeyPath:@"frameSize" context:(__bridge void*)self];

	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS context:NULL];
}

- (void)awakeFromNib
{
//    static BOOL __alreadyCalled = NO;
//    assert(NO == __alreadyCalled);
//    __alreadyCalled = YES;
    
    _observingHeaderValuesOfProjects = [NSMutableSet set];

    // Configure scrolling
    [[self scrollView] setVerticalScrollElasticity:NSScrollElasticityNone];
	[[self scrollView] setPostsBoundsChangedNotifications:YES];

	[self.scrollView.contentView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(scrollViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:self.scrollView.contentView];
//	[[[self scrollView] contentView] setBackgroundColor:[NSColor dayMapBackgroundColor]];

    // Configure table view
    NSRect headerFrame = [[self tableView] headerView].frame;
    headerFrame.size.height = 35;
    [[[self tableView] headerView] setFrame:headerFrame];
	ProjectTableHeaderCell *headerCell = [[ProjectTableHeaderCell alloc] initTextCell:@""];
	[[[[self tableView] tableColumns] lastObject] setHeaderCell:headerCell]; // initial empty column needs correct header cell. This cell will be copied and used by the table later.
	
    // Configure projects data
//    [(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"dayMap.projects" options:0 context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedProject" options:0 context:(__bridge void*)self];
    [self.view addObserver:self forKeyPath:@"frameSize" options:0 context:(__bridge void*)self];
    
//    [self observeValueForKeyPath:@"dayMap.projects" ofObject:[NSApp delegate] change:nil context:(__bridge void*)self];

	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS options:NSKeyValueObservingOptionNew
											   context:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(childrenDidChangeForParentNotification:) name:DMChildrenDidChangeForParentNotification object:nil];
}

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification {
	[DMCurrentManagedObjectContext removeObserver:self forKeyPath:@"dayMap.projects" context:(__bridge void*)self];

	for (Project *project in [self sortedProjects]) {
		NSString *identifier = project.uuid;
		if([_observingHeaderValuesOfProjects member:identifier]) {
			[project removeObserver:self forKeyPath:@"displayAttributes.color" context:(__bridge void*)_observingHeaderValuesOfProjects];
			[project removeObserver:self forKeyPath:@"archived" context:(__bridge void*)_observingHeaderValuesOfProjects];
			[project removeObserver:self forKeyPath:@"name" context:(__bridge void*)_observingHeaderValuesOfProjects];
			[_observingHeaderValuesOfProjects removeObject:identifier];
		}
	}

	[_observingHeaderValuesOfProjects removeAllObjects];

//	[[self tableView] beginUpdates];
//	for (NSTableColumn *column in [[[self tableView] tableColumns] copy]) {
//		[[self tableView] removeTableColumn:column];
//	}
//	[[self tableView] endUpdates];
}

- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	[_observingHeaderValuesOfProjects removeAllObjects];
	[DMCurrentManagedObjectContext addObserver:self forKeyPath:@"dayMap.projects" options:0 context:(__bridge void*)self];
	[self update];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"dayMap.projects"]) {
//			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC);
//			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//				[self update];
//			});
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
			[self performSelector:@selector(update) withObject:nil afterDelay:0.0];
        }
		else if ([keyPath isEqualToString:@"selectedProject"]) {
            NSInteger columnIndex = [[self tableView] columnWithIdentifier:[(DayMapAppDelegate *)[NSApp delegate] selectedProject]];
            NSIndexSet *selection = columnIndex != -1 ? [NSIndexSet indexSetWithIndex:columnIndex] : [NSIndexSet indexSet];
            [[self tableView] selectColumnIndexes:selection byExtendingSelection:NO];
        }
        else if ([keyPath isEqualToString:@"frameSize"]) {
            [[self tableView] noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:0]];
        }
    }
    else if (context == (__bridge void*)_observingHeaderValuesOfProjects) {
        Project *project = (Project *)object;
        NSString *identifier = project.uuid;
		NSTableColumn *column = [[self tableView] tableColumnWithIdentifier:identifier];
        ProjectTableHeaderCell *cell = (ProjectTableHeaderCell *)[column headerCell];
        
        if ([keyPath isEqualToString:@"displayAttributes.color"]) {
            // Deselect project. We don't want the selection drawing to affect header color. The user is now adjusting color and needs to see accurately.
            [(DayMapAppDelegate *)[NSApp delegate] setSelectedProject:nil];
            
			NSColor *color = [project.displayAttributes nativeColor];
			if (!color) color = [NSColor randomProjectColor];
			if (project == DMCurrentManagedObjectContext.dayMap.inbox) {
				color = [NSColor dayMapActionColor];
			}
			[cell setColor:color];
			[cell setArchived:[project.archived boolValue]];
			
            [[[self tableView] headerView] setNeedsDisplay:YES];
        }
        if ([keyPath isEqualToString:@"name"]) {
            [cell setTitleString:project.name];
			[column setHeaderToolTip:project.name];
            [[[self tableView] headerView] setNeedsDisplay:YES];
			
//			DLog(@"cell title = %@", project.name);
//			DLog(@"columns = %@", [[[self tableView] tableColumns] description]);
        }
		if ([keyPath isEqualToString:@"archived"]) {
			[self update];
		}
    }
	else if ([keyPath isEqualToString:PREF_SHOW_ARCHIVED_PROJECTS]) {
		[self update];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)childrenDidChangeForParentNotification:(NSNotification *)notification {
	// In response to user creating a new task, we want to scroll and unminimize project columns
	
	NSString *nextTaskToEdit = ((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit;
	if (!nextTaskToEdit) {
		return; // some other action is happening, but not a user creating a new task
	}
	
	Project *nextTaskToEditRoot = [(AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:[notification object]] rootProject];
	Project *notificationRoot = [(AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:[notification object]] rootProject];
	if (![nextTaskToEditRoot.uuid isEqualToString:notificationRoot.uuid]) { // Only update the column once since we will get a lot of notifications
		return;
	}
	
	for (Project *project in [self sortedProjects]) {
		NSString *identifier = project.uuid;

		if ([[nextTaskToEditRoot uuid] isEqual:identifier]) {
			// if added new task and project is minimized, then restore it and scroll to it
			NSString *key = [COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:identifier];
			BOOL isMinimized = [[NSUserDefaults standardUserDefaults] boolForKey:key];

			if (isMinimized) {
				NSTableColumn *column = [self.tableView tableColumnWithIdentifier:identifier];
				[self setTableColumn:column minimized:NO];
			}
			
			NSInteger columnIndex = [[self tableView] columnWithIdentifier:identifier];
			[[self tableView] scrollColumnToVisible:columnIndex];
		}
	}
}

- (NSArray *)sortedProjects {
	NSMutableSet *projects = [DMCurrentManagedObjectContext.dayMap.projects mutableCopy];

	if (![[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_ARCHIVED_PROJECTS]) {
		for (Project *project in [projects copy]) {
			if ([project.archived boolValue]) {
				[projects removeObject:project];
			}
		}
	}

	[projects addObject:DMCurrentManagedObjectContext.dayMap.inbox];
	if ([DMCurrentManagedObjectContext.dayMap.inbox.sortIndex integerValue] != -1) DMCurrentManagedObjectContext.dayMap.inbox.sortIndex = @(-1);
	NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	return sortedProjects;
}

- (void)update
{
    NSTableView *tableView = [self tableView];    
    [tableView beginUpdates];

    // Set number of columns according to number of projects
	NSArray *sortedProjects = [self sortedProjects];

    NSMutableDictionary *widthsPreference = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:COLUMN_WIDTHS_PREFERENCE] mutableCopy];
    if(!widthsPreference) widthsPreference = [NSMutableDictionary dictionary];
    
    for (NSTableColumn *column in [[tableView tableColumns] copy]) {
		BOOL minimized = [[NSUserDefaults standardUserDefaults] boolForKey:[COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[column identifier]]];
		if (!minimized) {
			[widthsPreference setObject:[NSNumber numberWithFloat:[column width]] forKey:[column identifier]];
		}
		[tableView removeTableColumn:column];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:widthsPreference forKey:COLUMN_WIDTHS_PREFERENCE];
    
	if (!DMCurrentManagedObjectContext) {
		[tableView endUpdates];
		return;
	}

    for (Project *project in sortedProjects) {
        NSString *identifier = project.uuid;
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
        [column setResizingMask:NSTableColumnUserResizingMask];
        [column setMinWidth:90];
        [column setMaxWidth:10000];
        ProjectTableHeaderCell *headerCell = [[ProjectTableHeaderCell alloc] initTextCell:@""];
        [column setHeaderCell:headerCell];
		
		BOOL minimized = [[NSUserDefaults standardUserDefaults] boolForKey:[COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[column identifier]]];

		if (minimized) {
			[column setMinWidth:40];
			[column setWidth:[column minWidth]];
			[column setMaxWidth:[column minWidth]];
			headerCell.minimized = minimized;
		}
		else {
			CGFloat width = [[widthsPreference objectForKey:identifier] floatValue];
			if(width == 0) width = 230; // default width
			[column setWidth:floor(MIN([column maxWidth], MAX([column minWidth], width)))];
		}
        
        [tableView addTableColumn:column];

        // Observe color and name changes, and update cell as appropriate.
        // We don't do this in the cell itself because KVO observing is tricky with the NSCopying protocol of cell reuse
        if([_observingHeaderValuesOfProjects member:identifier]) {
            [project removeObserver:self forKeyPath:@"displayAttributes.color" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [project removeObserver:self forKeyPath:@"archived" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [project removeObserver:self forKeyPath:@"name" context:(__bridge void*)_observingHeaderValuesOfProjects];
            [_observingHeaderValuesOfProjects removeObject:identifier];
        }
        [project addObserver:self forKeyPath:@"displayAttributes.color" options:0 context:(__bridge void*)_observingHeaderValuesOfProjects];
        [project addObserver:self forKeyPath:@"archived" options:0 context:(__bridge void*)_observingHeaderValuesOfProjects];
        [project addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)_observingHeaderValuesOfProjects];
        [_observingHeaderValuesOfProjects addObject:identifier];
        [self observeValueForKeyPath:@"displayAttributes.color" ofObject:project change:nil context:(__bridge void*)_observingHeaderValuesOfProjects];
        [self observeValueForKeyPath:@"name" ofObject:project change:nil context:(__bridge void*)_observingHeaderValuesOfProjects];
    }
    
    // Reload
    [tableView endUpdates];
    [tableView reloadData];
}

- (void)makeTaskVisibleNotification:(NSNotification *)notification
{
	NSString *taskUUID = [[notification userInfo] objectForKey:@"uuid"];
	
	AbstractTask *task = (AbstractTask *)[DMCurrentManagedObjectContext objectWithUUID:taskUUID];
	Project *root = [task rootProject];
	NSInteger columnIndex = [[self tableView] columnWithIdentifier:root.uuid];
	if (columnIndex != -1) {
		NSString *key = [COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:root.uuid];
		BOOL minimized = [[NSUserDefaults standardUserDefaults] boolForKey:key];
		if (minimized) {
			NSTableColumn *column = [self.tableView tableColumnWithIdentifier:root.uuid];
			[self setTableColumn:column minimized:NO];
		}

		[[self tableView] scrollColumnToVisible:columnIndex];
	}
}

- (void)scrollViewContentBoundsDidChange:(NSNotification *)notification {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(addProject:) object:self];
	if (NSMaxX(self.scrollView.contentView.documentVisibleRect) > [self.scrollView.documentView bounds].size.width + 35) {
		[self performSelector:@selector(addProject:) withObject:self afterDelay:0.2];
	}
}

#pragma mark - TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return 1; // only one row. This row is actually a view that contains another table view. This is goofy, but we want this so that each column can scroll separately.
}

// TODO V1 - need to get notification of scroll bar visible changes (e.g. plugged in mouse, or more items added and scroll bar appears) and need to recalculate size then.

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	NSSize size = [NSScrollView contentSizeForFrameSize:self.scrollView.frame.size horizontalScrollerClass:self.scrollView.horizontalScroller.class verticalScrollerClass:self.scrollView.verticalScroller.class borderType:self.scrollView.borderType controlSize:NSRegularControlSize scrollerStyle:self.scrollView.scrollerStyle];
    CGFloat height = size.height - [[self tableView] headerView].frame.size.height;
	if (height < 1) height = 1;
	return height;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	NSTableRowView *result = [tableView makeViewWithIdentifier:@"projectRow" owner:self];
	
	// There is no existing cell to reuse so we will create a new one
	if (result == nil) {
		result = [[ProjectTableRowView alloc] initWithFrame:self.tableView.bounds];
		
		// the identifier of the view instance is set to task. This
		// allows it to be re-used
		result.identifier = @"projectRow";
	}
	
	// return the result.
	return result;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    ProjectView *result = [tableView makeViewWithIdentifier:@"ProjectView" owner:self];
	
    // There is no existing cell to reuse so we will create a new one
    if (nil == result) {
		// create the new view with a frame of the {0,0} with the width of the table
		// note that the height of the frame is not really relevant, the row-height will modify the height
		// the new text field is then returned as an autoreleased object
        result = [[ProjectView alloc] initWithFrame:NSZeroRect]; // will resize later
        [result setAutoresizingMask:NSViewHeightSizable];
				
		// the identifier of the view instance is set to task. This
		// allows it to be re-used
		result.identifier = @"ProjectView";
	}
	
	result.project = nil;
	
	// result is now guaranteed to be valid, either as a re-used cell
	// or as a new cell, so set the value of the cell to the value at row
	if (DMCurrentManagedObjectContext) {
		NSUInteger columnIndex = [[tableView tableColumns] indexOfObject:tableColumn];
		if (columnIndex != NSNotFound) {
			NSArray *sortedProjects = [self sortedProjects];
			if (columnIndex < sortedProjects.count) {
				result.project = [sortedProjects objectAtIndex:columnIndex];
				result.isInbox = (result.project == DMCurrentManagedObjectContext.dayMap.inbox);
				result.minimized = ((ProjectTableHeaderCell *)tableColumn.headerCell).minimized;
			}
		}
	}
    
	// return the result.
	return result;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSUInteger index = [[tableView tableColumns] indexOfObject:tableColumn];
	NSArray *sortedProjects = [self sortedProjects];
    
	// Ignore if clicked inbox
	if ([tableColumn.identifier isEqualToString:DMCurrentManagedObjectContext.dayMap.inbox.uuid]) {
		[(DayMapAppDelegate *)[NSApp delegate] setSelectedProject:nil];
		[self.view.window makeFirstResponder:nil];
		return;
	}
	
    // Select Project
    [(DayMapAppDelegate *)[NSApp delegate] setSelectedProject:[[sortedProjects objectAtIndex:index] valueForKey:@"uuid"]];
    [self.view.window makeFirstResponder:nil];
	
    // Edit if double-clicked
    if ([[NSApp currentEvent] type] == NSLeftMouseUp && [[NSApp currentEvent] clickCount] > 1) {
        [self showProjectEditPopover:[sortedProjects objectAtIndex:index]];
    }
    
    [[[self tableView] headerView] setNeedsDisplay:YES];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
    // TODO V2 - Return NO for the add column
	if ([tableColumn.identifier isEqualToString:DMCurrentManagedObjectContext.dayMap.inbox.uuid]) {
		return NO;
	}
	else {
		return YES;
	}
}

- (void)tableView:(NSTableView *)tableView didClickHeaderMenuButtonForTableColumn:(NSTableColumn *)column {
	ProjectTableHeaderCell *headerCell = (ProjectTableHeaderCell *)[column headerCell];
	NSInteger projectIndex = [self.tableView.tableColumns indexOfObject:column];
	if (NSNotFound == projectIndex) return;

	Project *project = [[self sortedProjects] objectAtIndex:projectIndex];

	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *item = [menu addItemWithTitle:NSLocalizedString(@"Edit…", @"context menu") action:@selector(contextEdit:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];
	item = [menu addItemWithTitle:NSLocalizedString(@"Archive", @"context menu") action:@selector(contextArchive:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];
	item = [menu addItemWithTitle:NSLocalizedString(@"Delete…", @"context menu") action:@selector(contextDelete:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];
	
	[menu addItem:[NSMenuItem separatorItem]];

	item = [menu addItemWithTitle:NSLocalizedString(@"New Task…", @"context menu") action:@selector(contextNewTask:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];
	
	[menu addItem:[NSMenuItem separatorItem]];

	item = [menu addItemWithTitle:NSLocalizedString(@"Expand All Tasks", @"context menu") action:@selector(contextExpandAllTasks:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];

	item = [menu addItemWithTitle:NSLocalizedString(@"Collapse All Tasks", @"context menu") action:@selector(contextCollapseAllTasks:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];

	[menu addItem:[NSMenuItem separatorItem]];

	item = [menu addItemWithTitle:NSLocalizedString(@"Insert Project…", @"context menu") action:@selector(contextInsertProject:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:project];
	
	

	menu.delegate = headerCell;
	
	// Show menu
	NSRect buttonRect = [headerCell menuButtonFrameForCellFrame:[self.tableView.headerView headerRectOfColumn:projectIndex]];
	[menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(buttonRect.origin.x + 3, NSMaxY(buttonRect) + 3) inView:self.tableView.headerView];
}

- (void)tableView:(NSTableView *)tableView didToggleMinimizeForTableColumn:(NSTableColumn *)column {
	NSString *key = [COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[column identifier]];
	BOOL isMinimized = [[NSUserDefaults standardUserDefaults] boolForKey:key];

	if (WSIsOptionKeyPressed()) {
		BOOL allOthersAreMinimized = YES;
		for (NSTableColumn *c in [[self tableView] tableColumns]) {
			if ([c.identifier isEqualToString:column.identifier]) continue;
			NSString *key = [COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[c identifier]];
			if (![[NSUserDefaults standardUserDefaults] boolForKey:key]) {
				allOthersAreMinimized = NO;
				break;
			}
		}
		
		if (allOthersAreMinimized) {
			// Maximize all
			for (NSTableColumn *c in [[self tableView] tableColumns]) {
				[self setTableColumn:c minimized:NO];
			}
			NSInteger columnIndex = [[self.tableView tableColumns] indexOfObject:column];
			[self.tableView scrollColumnToVisible:columnIndex];
		}
		else {
			// Minimize all but column
			for (NSTableColumn *c in [[self tableView] tableColumns]) {
				if ([c.identifier isEqualToString:column.identifier]) {
					[self setTableColumn:c minimized:NO];
				}
				else {
					[self setTableColumn:c minimized:YES];
				}
			}
		}
	}
	else {
		[self setTableColumn:column minimized:!isMinimized];
	}
}

- (void)setTableColumn:(NSTableColumn *)column minimized:(BOOL)minimized {
	NSString *key = [COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[column identifier]];
	BOOL isMinimized = [[NSUserDefaults standardUserDefaults] boolForKey:key];

	if (isMinimized == minimized) {
		return;
	}

	[[NSUserDefaults standardUserDefaults] setBool:minimized forKey:key];

	((ProjectTableHeaderCell *)column.headerCell).minimized = minimized;
	
	NSInteger columnIndex = [[self.tableView tableColumns] indexOfObject:column];
	((ProjectView *)[self.tableView viewAtColumn:columnIndex row:0 makeIfNecessary:NO]).minimized = minimized;

	if (minimized) {
		[column setMinWidth:40];
		[column setWidth:[column minWidth]];
		[column setMaxWidth:[column minWidth]];
	}
	else {
		NSMutableDictionary *widthsPreference = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:COLUMN_WIDTHS_PREFERENCE] mutableCopy];
		
		CGFloat width = [[widthsPreference objectForKey:[column identifier]] floatValue];
		if(width == 0) width = 160; // default width
		[column setMaxWidth:10000];
		[column setWidth:floor(MIN([column maxWidth], MAX([column minWidth], width)))];
		[column setMinWidth:90];
		[self.tableView scrollColumnToVisible:columnIndex];
	}
}

//- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
//{
//  // This is for when the user double-clicks the resize widget
//    // TODO V2
//}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    NSMutableDictionary *widthsPreference = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:COLUMN_WIDTHS_PREFERENCE] mutableCopy];
    if(!widthsPreference) widthsPreference = [NSMutableDictionary dictionary];

    for (NSTableColumn *column in [[self tableView] tableColumns]) {
		BOOL minimized = [[NSUserDefaults standardUserDefaults] boolForKey:[COLUMN_MINIMIZED_PREFERENCE stringByAppendingString:[column identifier]]];
        if(!minimized) {
			[widthsPreference setObject:[NSNumber numberWithFloat:[column width]] forKey:[column identifier]];
		}
    }

    [[NSUserDefaults standardUserDefaults] setObject:widthsPreference forKey:COLUMN_WIDTHS_PREFERENCE];
}

- (void)tableViewColumnDidMove:(NSNotification *)notification
{
	static BOOL __reorderingProjects = NO;
	if (__reorderingProjects) return;
	
	NSUInteger oldColumnIndex = [[[notification userInfo] objectForKey:@"NSOldColumn"] unsignedIntegerValue];
    NSUInteger newColumnIndex = [[[notification userInfo] objectForKey:@"NSNewColumn"] unsignedIntegerValue];
	
	// If the user moved a project to before the inbox, move it back.
	NSArray *sortedProjects = [self sortedProjects];
	BOOL firstColumnIsInbox = sortedProjects.count > 0 && [sortedProjects objectAtIndex:0] == DMCurrentManagedObjectContext.dayMap.inbox;
	
	if (0 == newColumnIndex && firstColumnIsInbox) {
		__reorderingProjects = YES;
		[[self tableView] moveColumn:0 toColumn:oldColumnIndex];
		__reorderingProjects = NO;
		return;
	}
	
	NSMutableOrderedSet *orderedProjects;
	if (firstColumnIsInbox) {
		oldColumnIndex--;
		newColumnIndex--;
		orderedProjects = [NSMutableOrderedSet orderedSetWithArray:sortedProjects range:NSMakeRange(1, sortedProjects.count - 1) copyItems:NO];
	}
	else {
		orderedProjects = [NSMutableOrderedSet orderedSetWithArray:sortedProjects];
	}
	
    // Save new project order to data model
	[orderedProjects moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:oldColumnIndex] toIndex:newColumnIndex];
	NSInteger i = 0;
	for (Project *project in orderedProjects) { // update sortIndex
		project.sortIndex = [NSNumber numberWithInteger:i];
		i++;
	}
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn {
	// Prevent drag reordering of inbox
	if ([tableColumn.identifier isEqualToString:DMCurrentManagedObjectContext.dayMap.inbox.uuid]) {
		[tableView setAllowsColumnReordering:NO];
	}
	else {
		[tableView setAllowsColumnReordering:YES];
	}
}

#pragma mark - Menu

- (void)contextEdit:(NSMenuItem *)sender {
	[self showProjectEditPopover:[sender representedObject]];
}

- (void)contextDelete:(NSMenuItem *)sender {
	Project *project = (Project *)[sender representedObject];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete '%@'?", @"delete project message"), project.name]];
	[alert setInformativeText:NSLocalizedString(@"Deleting this Project will also delete its Tasks and Subtasks.", @"delete project message info")];
	[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"delete project confirmation button")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"delete project confirmation button")];
	
	[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
		if (NSAlertFirstButtonReturn == returnCode) {
			[DMCurrentManagedObjectContext deleteObject:[sender representedObject]];
		}
	}];
}

- (void)contextArchive:(NSMenuItem *)sender {
	Project *project = [sender representedObject];
	BOOL archived = [project.archived boolValue];
	[project setArchivedWithInfoAlert:!archived];
}

- (void)contextNewTask:(NSMenuItem *)sender {
	Project *project = [sender representedObject];
	Task *task = [Task task];

	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = task.uuid;

	NSMutableSet *tasks = [project mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
}

- (void)contextInsertProject:(NSMenuItem *)sender {
	Project *project = [sender representedObject];
	NSArray *sortedProjects = [self sortedProjects];

	NSInteger projectIndex = [sortedProjects indexOfObject:project];

	for (NSInteger i = 1; i < sortedProjects.count; i++) {
		Project *projectToShift = sortedProjects[i];
		if (i <= projectIndex) {
			projectToShift.sortIndex = @(i);
		}
		else {
			projectToShift.sortIndex = @(i + 1);
		}
	}

	[self addProjectAtIndex:projectIndex + 1];
}

- (void)contextExpandAllTasks:(id)sender {
	Project *project = [sender representedObject];
	NSInteger columnIndex = [[self tableView] columnWithIdentifier:project.uuid];
	if (columnIndex != -1) {
		ProjectView *view = (ProjectView *)[self.tableView viewAtColumn:columnIndex row:0 makeIfNecessary:NO];
		[view expandAll];
	}
}

- (void)contextCollapseAllTasks:(id)sender {
	Project *project = [sender representedObject];
	NSInteger columnIndex = [[self tableView] columnWithIdentifier:project.uuid];
	if (columnIndex != -1) {
		ProjectView *view = (ProjectView *)[self.tableView viewAtColumn:columnIndex row:0 makeIfNecessary:NO];
		[view collapseAll];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	BOOL returnValue = YES;

	Project *project = nil;
	if ([[menuItem representedObject] isKindOfClass:[Project class]]) {
		project = [menuItem representedObject];
	}

	if (@selector(contextEdit:) == menuItem.action) {
		BOOL allowed = (project != DMCurrentManagedObjectContext.dayMap.inbox);
		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}

	else if (@selector(contextDelete:) == menuItem.action) {
		BOOL allowed = (project != DMCurrentManagedObjectContext.dayMap.inbox);
		[menuItem setHidden:!allowed];
		returnValue = allowed;
	}

	else if (@selector(contextArchive:) == menuItem.action) {
		BOOL allowed = (project != DMCurrentManagedObjectContext.dayMap.inbox);
		[menuItem setHidden:!allowed];
		BOOL archived = [project.archived boolValue];
		if (archived) {
			menuItem.title = NSLocalizedString(@"Unarchive", @"context menu");
		}
		else {
			menuItem.title = NSLocalizedString(@"Archive", @"context menu");
		}
		returnValue = allowed;
	}

	else if (@selector(contextNewTask:) == menuItem.action) {
		returnValue = YES;
	}
	
	else if (@selector(contextExpandAllTasks:) == menuItem.action) {
		NSInteger columnIndex = [[self tableView] columnWithIdentifier:project.uuid];
		if (columnIndex != -1) {
			ProjectView *view = (ProjectView *)[self.tableView viewAtColumn:columnIndex row:0 makeIfNecessary:NO];
			returnValue = [view canExpandAll];
		}
	}

	else if (@selector(contextCollapseAllTasks:) == menuItem.action) {
		NSInteger columnIndex = [[self tableView] columnWithIdentifier:project.uuid];
		if (columnIndex != -1) {
			ProjectView *view = (ProjectView *)[self.tableView viewAtColumn:columnIndex row:0 makeIfNecessary:NO];
			returnValue = [view canCollapseAll];
		}
	}

	[menuItem.menu cleanUpSeparators];

	return returnValue;
}

#pragma mark - Actions
- (IBAction)addProject:(id)sender {
	[self addProjectAtIndex:-1];
}

- (Project *)addProjectAtIndex:(NSInteger)index {
	if (!DMCurrentManagedObjectContext) return nil;

//	if ([self sortedProjects].count >= 3 && !WSDayMapFullyPurchased()) {
//		// TODO - show nice purchase nudge screen
//		NSLog(@"Need to purchase additional projects");
//		return;
//	}
	
    Project *project = [Project project];
	
    NSManagedObject *displayAttrs = [NSEntityDescription
                                     insertNewObjectForEntityForName:@"ProjectDisplayAttributes" 
                                     inManagedObjectContext:DMCurrentManagedObjectContext];
	[displayAttrs setValue:WSCreateUUID() forKey:@"uuid"];
	[(ProjectDisplayAttributes *)displayAttrs setNativeColor:[NSColor randomProjectColor]];
	[project setValue:displayAttrs forKey:@"displayAttributes"];
    
    NSMutableSet *projects = [DMCurrentManagedObjectContext.dayMap mutableSetValueForKey:@"projects"];
	NSArray *sortedProjects = [projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	if (index == -1) {
		project.sortIndex = @([[[sortedProjects lastObject] sortIndex] integerValue] + 1);
	}
	else {
		project.sortIndex = @(index);
	}

    [projects addObject:project];
		
	[self update];
    
    // we just added this new project and want to edit it
	if (index == -1) {
		[[self tableView] scrollColumnToVisible:[[self tableView] numberOfColumns]-1];
	}
	else {
		[[self tableView] scrollColumnToVisible:index];
	}
    [self showProjectEditPopover:project];

	return project;
}

- (void)showProjectEditPopover:(Project *)project
{
    if(![self.view window]) return;
    
    NSPopover *popover = [[NSPopover alloc] init];
	popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    popover.behavior = NSPopoverBehaviorSemitransient;
    popover.animates = YES;
    
    ProjectEditPopoverViewController *viewController = [ProjectEditPopoverViewController projectEditPopoverViewController];
    viewController.popover = popover;
    viewController.project = project;
    popover.contentViewController = viewController;
	popover.delegate = viewController;

    NSString *identifier = project.uuid;
    NSUInteger columnIndex = [[self tableView] columnWithIdentifier:identifier];
    if(columnIndex != -1) {
        [popover showRelativeToRect:[[[self tableView] headerView] headerRectOfColumn:columnIndex] ofView:[[self tableView] headerView] preferredEdge:CGRectMaxXEdge];
    }
}

@end
