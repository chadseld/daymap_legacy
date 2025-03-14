//
//  SearchController.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/3/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "SearchController.h"
#import "SearchResultTableCellView.h"
#import "RoundedTaskTableRowView.h"
#import "DayMapAppDelegate.h"
#import "AbstractTask+Additions.h"
#import "ProjectDisplayAttributes+Additions.h"
#import "NSColor+WS.h"
#import "MiscUtils.h"

#define ROW_HEIGHT 47

@interface SearchController () {
	NSMutableArray *_searchResults;
	BOOL _amUpdatingSelection;
}

@end

@implementation SearchController

- (void)awakeFromNib
{
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedTasks" options:0 context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"selectedProject" options:0 context:(__bridge void*)self];	
	[(DayMapAppDelegate *)[NSApp delegate] addObserver:self forKeyPath:@"completedDateFilter" options:0 context:(__bridge void*)self];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeManagedObjectContextNotification:) name:DMWillChangeManagedObjectContext object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeManagedObjectContextNotification:) name:DMDidChangeManagedObjectContext object:nil];

	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS options:NSKeyValueObservingOptionNew
											   context:NULL];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedTasks" context:(__bridge void*)self];
    [(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"selectedProject" context:(__bridge void*)self];
	[(DayMapAppDelegate *)[NSApp delegate] removeObserver:self forKeyPath:@"completedDateFilter" context:(__bridge void*)self];

	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_SHOW_ARCHIVED_PROJECTS context:NULL];
}

- (void)willChangeManagedObjectContextNotification:(NSNotification *)notification {
}

- (void)didChangeManagedObjectContextNotification:(NSNotification *)notification {
	[self.searchResultsTableView reloadData];
}

- (void)updateSelection
{
	_amUpdatingSelection = YES;
	BOOL selected = NO;
	// combine tasks and projects
	NSMutableSet *allSelected = [NSMutableSet new];
	[allSelected unionSet:[(DayMapAppDelegate *)[NSApp delegate] selectedTasks]];
	if ([(DayMapAppDelegate *)[NSApp delegate] selectedProject]) {
		[allSelected addObject:[(DayMapAppDelegate *)[NSApp delegate] selectedProject]];
	}
	
	[self.searchResultsTableView selectRowIndexes:[NSIndexSet indexSet]byExtendingSelection:NO];
	for (NSString *uuid in allSelected) {
		for (NSInteger rowIndex = 0; rowIndex < _searchResults.count; rowIndex++) {
			NSManagedObject *obj = [_searchResults objectAtIndex:rowIndex];
			if ([[obj valueForKey:@"uuid"] isEqual:uuid]) {
				[self.searchResultsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:YES];
				selected = YES;
				break;
			}
		}
	}
	if (!selected) {
		[self.searchResultsTableView selectRowIndexes:[NSIndexSet indexSet]byExtendingSelection:NO];
	}
	_amUpdatingSelection = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"completedDateFilter"]) {
			[self setSearchString:self.searchString]; // refresh
        }
        else if ([keyPath isEqualToString:@"selectedTasks"] || [keyPath isEqualToString:@"selectedProject"]) {
			[self updateSelection];
        }
    }
	else if ([keyPath isEqualToString:PREF_SHOW_ARCHIVED_PROJECTS]) {
		[self setSearchString:self.searchString];
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setSearchString:(NSString *)searchString
{
	_searchString = searchString;

	if (!_searchResults) _searchResults = [NSMutableArray new];
	[_searchResults removeAllObjects];
	
	if (!_searchString) {
		[self.searchResultsTableView reloadData];
		return;
	}

	// Task
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"AbstractTask" inManagedObjectContext:DMCurrentManagedObjectContext]];
	NSError *error;
	NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	NSArray *firstFilteredResult = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors([NSSet setWithArray:result], [(DayMapAppDelegate *)[NSApp delegate] completedDateFilter], nil, SORT_BY_SORTINDEX);
	
	// Second pass, remove tasks if their parent task was removed on the first pass.
	// We don't want to return search results when the parents are hidden.
	// Also remove tasks with archived parent projects
	NSMutableArray *filteredResult = [[NSMutableArray alloc] initWithCapacity:firstFilteredResult.count];
	BOOL showArchived = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_ARCHIVED_PROJECTS];
	for (AbstractTask *task in firstFilteredResult) {
		// Don't search archived projects
		if (!showArchived && [[task rootProject].archived boolValue]) {
			continue;
		}

		// Don't search tasks with parents that are hidden by WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors
		BOOL parentIsHidden = NO;
		NSArray *breadcrumbs = [task breadcrumbs];
		for (AbstractTask *parent in breadcrumbs) {
			if (![firstFilteredResult containsObject:parent]) {
				parentIsHidden = YES;
				break;
			}
		}
		if (parentIsHidden) {
			continue;
		}

		[filteredResult addObject:task];
	}

	// Add Search results
	for (AbstractTask *obj in filteredResult) {
		NSString *name = obj.name;
		NSString *details = [obj.attributedDetailsAttributedString string];
		NSString *type = obj.entity.name;
		NSString *uuid = obj.uuid;
		NSRange range;
		
		if (name && (range = [name rangeOfString:_searchString options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch]).location != NSNotFound) {
			NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:name];
			[attributedName addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:14] range:range];
			if ([obj.entity.name isEqualToString:@"Task"] && [[obj valueForKey:@"completed"] intValue] == TASK_COMPLETED) {
				[attributedName addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [attributedName length])];
			}
			
			NSString *breadcrumbs = [[[obj breadcrumbs] valueForKey:@"name"] componentsJoinedByString:@" > "];

			NSColor *projectColor = [[((AbstractTask *)obj) rootProject].displayAttributes nativeColor];
			if (!projectColor) projectColor = [NSColor blackColor];

			[_searchResults addObject:@{@"name": attributedName, @"type" : type, @"breadcrumbs" : breadcrumbs, @"projectColor" : projectColor, @"uuid" : uuid}];
		}
		else if (details && (range = [details rangeOfString:_searchString options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch]).location != NSNotFound) {
			NSMutableAttributedString *attributedName = [[NSMutableAttributedString alloc] initWithString:name];
			if ([obj.entity.name isEqualToString:@"Task"] && [[obj valueForKey:@"completed"] intValue] == TASK_COMPLETED) {
				[attributedName addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [attributedName length])];
			}
			
			NSString *breadcrumbs = [[[obj breadcrumbs] valueForKey:@"name"] componentsJoinedByString:@" > "];
			
			NSColor *projectColor = [[((AbstractTask *)obj) rootProject].displayAttributes nativeColor];
			if (!projectColor) projectColor = [NSColor blackColor];
			
			[_searchResults addObject:@{@"name": attributedName, @"type" : type, @"breadcrumbs" : breadcrumbs, @"projectColor" : projectColor, @"uuid" : uuid}];
		}
	}
	
	[self.searchResultsTableView reloadData];
}

#pragma mark - TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _searchResults.count;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	RoundedTaskTableRowView *result = [tableView makeViewWithIdentifier:@"searchRow" owner:self];
	
	// There is no existing cell to reuse so we will create a new one
	if (result == nil) {
		result = [[RoundedTaskTableRowView alloc] initWithFrame:NSMakeRect(0, 0, self.searchResultsTableView.bounds.size.width, ROW_HEIGHT)];
		
		// the identifier of the view instance is set to task. This
		// allows it to be re-used
		result.identifier = @"searchRow";
	}
		
	// return the result.
	return result;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// get an existing cell with the task identifier if it exists
    SearchResultTableCellView *result = [tableView makeViewWithIdentifier:@"searchResult" owner:self];
	
	result.textField.attributedStringValue = [[_searchResults objectAtIndex:row] valueForKey:@"name"];
	result.contextLabel.stringValue = [[_searchResults objectAtIndex:row] valueForKey:@"breadcrumbs"];
	result.projectColor = [[_searchResults objectAtIndex:row] valueForKey:@"projectColor"];
	result.type = [[_searchResults objectAtIndex:row] valueForKey:@"type"];
	result.uuid = [[_searchResults objectAtIndex:row] valueForKey:@"uuid"];
	
	return result;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return ROW_HEIGHT;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (_amUpdatingSelection) return;
	
	if (-1 == self.searchResultsTableView.selectedRow) return;
	
	NSDictionary *obj = [_searchResults objectAtIndex:self.searchResultsTableView.selectedRow];
	[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : [obj valueForKey:@"uuid"]}];
	if ([[obj valueForKey:@"type"] isEqualTo:@"Project"]) {
		[(DayMapAppDelegate *)[NSApp delegate] setSelectedProject:[obj valueForKey:@"uuid"]];
	}
	else {
		[(DayMapAppDelegate *)[NSApp delegate] setSelectedTasks:[NSSet setWithObject:[obj valueForKey:@"uuid"]]];
	}
}

- (IBAction)tableViewAction:(id)sender
{
	if ([[NSApp currentEvent] type] == NSLeftMouseUp && [NSApp currentEvent].clickCount == 2 && [self.searchResultsTableView clickedRow] >=0) {
		SearchResultTableCellView *cellView = [self.searchResultsTableView viewAtColumn:0 row:[self.searchResultsTableView clickedRow] makeIfNecessary:NO];
		if ([cellView isKindOfClass:[SearchResultTableCellView class]]) {
			[cellView showPopover];
		}
	}
}

@end
