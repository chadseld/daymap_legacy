//
//  QuickAddWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/26/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import "QuickAddWindowController.h"
#import "DayMapAppDelegate.h"
#import "Task.h"
#import "Task+Additions.h"
#import "DayMap.h"
#import "MiscUtils.h"
#import "AbstractTask+Additions.h"

@implementation QuickAddWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"QuickAddWindow"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)windowWillClose:(NSNotification *)notification
{
	[(DayMapAppDelegate *)[NSApp delegate] quickAddClosed];
}

- (IBAction)add:(id)sender
{
	if ([self.nameField.stringValue length] == 0) {
		NSBeep();
		return;
	}
	
	// Create new task
	Task *task = [Task task];
	task.name = self.nameField.stringValue;
	task.attributedDetailsAttributedString = self.descriptionTextView.textStorage;
	
	// Make sure not to Schedule to Edit task
	((DayMapAppDelegate *)[NSApp delegate]).nextTaskToEdit = nil;
		
	// parent is inbox
	NSManagedObject *parent = DMCurrentManagedObjectContext.dayMap.inbox;
	
	// Add new task to parent
	NSMutableSet *tasks = [parent mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];

	[self close];
}

@end
