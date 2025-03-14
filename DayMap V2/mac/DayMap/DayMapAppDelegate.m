//
//  DayMapAppDelegate.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/20/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "DayMapAppDelegate.h"
#import "Project.h"
#import "Task.h"
#import "Task+Additions.h"
#import "DayMap.h"
#import "NSDate+WS.h"
#import "MiscUtils.h"
#import "PrintView.h"
#import "RecoveryWindowController.h"
#import "WelcomeWindowController.h"
#import "NSMenu+WS.h"
#import "ChimpKit.h"


@implementation DayMapAppDelegate {
	PreferencesWindowController *_preferencesWindowController;
	QuickAddWindowController *_quickAddWindowController;
	RecoveryWindowController *_recoveryWindowController;
#if defined(TARGET_DAYMAP_LITE)
	UpgradeNudgeWindowController *_upgradeNudgeWindowController;
#endif
	WelcomeWindowController *_welcomeWindowController;
	PrintView *_printView;
	BOOL _terminating;
}

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - Projects Data Accessors

- (NSDate *)completedDateFilter
{
	NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:PREF_HIDE_COMPLETED_INTERVAL];
	if (0 == value ) { // hide all
		return [NSDate distantFuture];
	}
	else if (91 == value) { // none
		return [NSDate distantPast];
	}
	else {
		return [[NSDate today] dateByAddingDays:-value];
	}
}

#pragma mark - NSApplicationDelegate

- (IBAction)openMainWindow:(id)sender {
	[self.mainWindowController showWindow:self];
	[self.mainWindowController.window makeKeyAndOrderFront:self];
	[self.mainWindowController.window makeMainWindow];
//    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)openRecoveryWindow:(id)sender {
	_recoveryWindowController = [[RecoveryWindowController alloc] init];
	[[_recoveryWindowController window] makeKeyAndOrderFront:self];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication*)application {
	return (DMCurrentManagedObjectContext != nil); // to force applicationOpenUntitledFile
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
	[self openMainWindow:self];
	return YES;
}

//- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
//	return YES;
//}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	if (WSIsOptionKeyPressed()) {
		[self openRecoveryWindow:nil];
		return;
	}
	
	if (_terminating) {
		return;
	}
	
	[NSApp setMainMenu:self.mainMenu];

	self.aboutMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @"menu item"), [[NSRunningApplication currentApplication] localizedName]];
	self.hideMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Hide %@", @"menu item"), [[NSRunningApplication currentApplication] localizedName]];
	self.quitMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @"menu item"), [[NSRunningApplication currentApplication] localizedName]];

#ifndef TARGET_DAYMAP_LITE
	[self.upgradeToFullVersionMenuItem setHidden:YES];
#endif

	NSMutableDictionary *defaultDefaults = [NSMutableDictionary dictionary];
	[defaultDefaults setValue:@(7) forKey:PREF_HIDE_COMPLETED_INTERVAL];
	[defaultDefaults setValue:@(90) forKey:PREF_DELETE_COMPLETED_ITEMS_AFTER_TIME_DAYS];
	[defaultDefaults setValue:@(0.3694) forKey:PREF_RAND_PROJECT_COLOR];
	[defaultDefaults setValue:@(NO) forKey:PREF_SHOW_EVENTKIT_EVENTS];
	[defaultDefaults setValue:@(YES) forKey:PREF_SHOW_NOTES_IN_OUTLINE];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultDefaults];
	
	self.eventKitBridge = [[DMEventKitBridge alloc] init];
	
	// Register for error saving data
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(errorSavingContextNotification:)
												 name:@"WSErrorSavingContextNotification"
											   object:nil];
	// Register Quick Add hotkey
	[self updateQuickAddShortcut];
    
    // Load Core Data
	[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:nil userInfo:nil];
    [self setupCoreDataStack];
	[self loadPersistentStoreStartupWorkflow];
    	
	// Register for change notification
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(managedObjectContextObjectsDidChangeNotification:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:nil];

	// Set managedObjectContext for the UI. This tells the UI it's okay to start loading things.
	[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];


	[self openMainWindow:nil];

	[self checkToImportDayMapLiteData];
	
	// Create new project if none are yet created
	// Note - on a new install, if there is iCloud data, the iCloud data has not yet merged with our db yet, so this comes up in error.
	// So, only do this if not using iCloud.
	NSSet *projects = DMCurrentManagedObjectContext.dayMap.projects;
	if (projects.count == 0 && !WSPrefUseICloudStorage()) {
		[self performSelector:@selector(performWelcome) withObject:nil afterDelay:1];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOULD_DELETE_COMPLETED_ITEMS_AFTER_TIME]) {
		[self deleteCompletedTasksOlderThan:[[NSDate today] dateByAddingDays:-1 * [[NSUserDefaults standardUserDefaults] integerForKey:PREF_DELETE_COMPLETED_ITEMS_AFTER_TIME_DAYS]]];
	}
}

- (void)performWelcome {
	if (!_welcomeWindowController) {
		_welcomeWindowController = [[WelcomeWindowController alloc] init];
	}

	[self.mainWindowController.window beginSheet:_welcomeWindowController.window completionHandler:^(NSModalResponse returnCode) {
		[self welcomeWindowDidEnd];
	}];
}

- (void)welcomeWindowDidEnd {
	if (_welcomeWindowController.emailAddressTextField.stringValue.length > 0) {
		[self addEmailToMailingList:_welcomeWindowController.emailAddressTextField.stringValue];
	}
	
	if (NSOnState == _welcomeWindowController.useSampleDataCheckbox.state) {
		NSURL *demoDataURL = [[NSBundle mainBundle] URLForResource:@"FullDemoDataDayMap" withExtension:@"b_storedata"];
#ifdef TARGET_DAYMAP_LITE
		demoDataURL = [[NSBundle mainBundle] URLForResource:@"LiteDemoDayMapLite" withExtension:@"b_storedata"];
#endif
		NSError *error = nil;
		[DMCurrentManagedObjectContext save:&error];
		[DMCurrentManagedObjectContext forceBackup];

		[[NSNotificationCenter defaultCenter] postNotificationName:DMWillChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];
		[self disableFilePresenter];
		[self unloadPersistentStore];
		[self tearDownCoreDataStack];
		
		// Copy
		[[NSFileManager defaultManager] removeItemAtURL:[self localStoreURL] error:&error];
		[[NSFileManager defaultManager] copyItemAtURL:demoDataURL toURL:[self localStoreURL] error:&error];
		
		[self setupCoreDataStack];
		[self loadPersistentStoreAtPresentedItemURL];
		[self enableFilePresenterForURL:[self presentedItemURL]];
		[[NSNotificationCenter defaultCenter] postNotificationName:DMDidChangeManagedObjectContext object:DMCurrentManagedObjectContext userInfo:nil];

		// Update task week
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[NSEntityDescription entityForName:@"Task" inManagedObjectContext:DMCurrentManagedObjectContext]];
		NSArray *result = [DMCurrentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		for (Task *task in result) {
			if (task.scheduledDate) {
				task.scheduledDate = [task.scheduledDate dateInCurrentWeek];
			}
			if (TASK_COMPLETED == [task.completed integerValue] && task.completedDate) {
				task.completedDate = [task.completedDate dateInCurrentWeek];
			}
		}
	}
	else {
		[self.mainWindowController performSelector:@selector(addProject:) withObject:nil afterDelay:1];
	}
}

- (void)addEmailToMailingList:(NSString *)email {
	[[ChimpKit sharedKit] setApiKey:@"<redacted>"];
	
	NSDictionary *params = @{@"id" : @"<redacted>",
							 @"email" : @{@"email": email},
							 @"double_optin" : @"false",
							 @"update_existing" : @"true"};
	
	[[ChimpKit sharedKit] callApiMethod:@"lists/subscribe"
							 withParams:params
				   andCompletionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
					   NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					   DLog(@"Email subscribe response String: %@", responseString);
//					   id parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//					   
//					   if (![parsedResponse isKindOfClass:[NSDictionary class]] || ![parsedResponse[@"email"] isKindOfClass:[NSString class]] || error) {
//						   
//					   }
				   }];

}

#pragma mark - Core Data

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	_terminating = YES;
	
	// Astonishingly, this is not called by the framework before terminating.
	[[NSUserDefaults standardUserDefaults] synchronize];

	// Save changes in the application's managed object context before the application terminates.
    __block NSApplicationTerminateReply reply = NSTerminateNow;
    
    NSManagedObjectContext *context = DMCurrentManagedObjectContext;
    
	if (!context) {
        return NSTerminateNow;
    }

    [context performBlockAndWait:^{
        if (![context commitEditing]) {
            NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
            reply = NSTerminateCancel;
        }
        
        if (![context hasChanges]) {
            reply = NSTerminateNow;
        }
        
        NSError *error = nil;
        if (![context save:&error] && error) {
            // Customize this code block to include application-specific recovery steps.              
            BOOL result = [sender presentError:error];
            if (result) {
                reply = NSTerminateCancel;
            }
            
            NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
            NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
            NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
            NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:question];
            [alert setInformativeText:info];
            [alert addButtonWithTitle:quitButton];
            [alert addButtonWithTitle:cancelButton];
            
            NSInteger answer = [alert runModal];
            
            if (answer == NSAlertAlternateReturn) {
                reply = NSTerminateCancel;
            }
        }
    }];
	
    return reply;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return NO;
}

- (void)errorSavingContextNotification:(NSNotification *)notification
{
	NSError *error = [[notification userInfo] objectForKey:@"error"];
    // Don't need to display error for these
    if ([[error domain] isEqualToString:@"DAYMAP"]) {
        return;
    }
    // Legitimate error from core data, those we show
	NSString *errorString = [error localizedDescription];
	NSRunCriticalAlertPanel(NSLocalizedString(@"Error saving DayMap data", @"error dialog"), 
							[errorString stringByAppendingString:NSLocalizedString(@"\n\nYou should restart DayMap before making any further changes.", @"error dialog")], 
							NSLocalizedString(@"OK", @"error dialog"), nil, nil);

}

#pragma mark - IBActions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSManagedObject *selectedProject = [DMCurrentManagedObjectContext objectWithUUID:self.selectedProject];
	NSSet *selectedTasks = [DMCurrentManagedObjectContext objectsWithUUIDs:self.selectedTasks];

	if ([menuItem action] == @selector(duplicate:)) {
        return self.mainWindowController.window.isVisible && ([selectedTasks count] == 1 || selectedProject != nil);
    }
    if ([menuItem action] == @selector(delete:)) {
        return self.mainWindowController.window.isVisible && ([selectedTasks count] > 0 || selectedProject != nil);
    }
	if ([menuItem action] == @selector(addSubtask:)) {
        return self.mainWindowController.window.isVisible && [selectedTasks count] > 0;
	}
	if ([menuItem action] == @selector(indentSelectedTasks:) || [menuItem action] == @selector(outdentSelectedTasks:)) {
		return self.mainWindowController.window.isVisible && [selectedTasks count] > 0;
	}
    if ([menuItem action] == @selector(printSelectedProjects:)) {
		return self.mainWindowController.window.isVisible && (selectedProject != nil);
	}

	return YES;
}

- (IBAction)addTask:(id)sender
{
	[self openMainWindow:nil];
	
	// Create new task
	Task *task = [Task task];
	
	// Schedule to Edit task
	self.nextTaskToEdit = task.uuid;
	
	// 1st choice is selected project
	NSManagedObject *parent = [DMCurrentManagedObjectContext objectWithUUID:self.selectedProject];
	
	// 2nd choice is sibling of selected task
	NSManagedObject *sibling = nil;
	NSSet *selectedTasks = [DMCurrentManagedObjectContext objectsWithUUIDs:self.selectedTasks];
	if (nil == parent && [selectedTasks count] == 1) {
		parent = [[selectedTasks anyObject] valueForKey:@"parent"];
		sibling = [selectedTasks anyObject];
	}
	
	// 3rd choice is inbox
	if (nil == parent) {
		parent = DMCurrentManagedObjectContext.dayMap.inbox;
	}

	// Set sort index
	NSInteger index = -1;
	if (sibling) {
		NSMutableSet *tasks = [parent mutableSetValueForKey:@"children"];
		NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
		index = [sortedTasks indexOfObject:sibling] + 1;
	}
	
	// Add new task to parent
	WSMoveTasksToParent(@[task], parent, index, NO);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:DMMakeTaskVisibleNotification object:nil userInfo:@{@"uuid" : task.uuid}];
	});
}

- (IBAction)addSubtask:(id)sender {
	NSString *parentUUID = [[self selectedTasks] anyObject];
	if (!parentUUID) return;
	
	Task *parent = (Task *)[DMCurrentManagedObjectContext objectWithUUID:parentUUID];
	
	Task *task = [Task task];
	
	self.nextTaskToEdit = task.uuid;

	NSMutableSet *tasks = [parent mutableSetValueForKey:@"children"];
	NSArray *sortedTasks = [tasks sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	task.sortIndex = [NSNumber numberWithInteger:[[[sortedTasks lastObject] sortIndex] integerValue] + 1];
	[tasks addObject:task];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:[parent valueForKey:@"uuid"] userInfo:nil];
}

- (IBAction)delete:(id)sender
{
	NSSet *selectedTasks = [DMCurrentManagedObjectContext objectsWithUUIDs:self.selectedTasks];
	Project *selectedProject = (Project *)[DMCurrentManagedObjectContext objectWithUUID:self.selectedProject];
	
	if (selectedProject) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete '%@'?", @"delete project message"), selectedProject.name]];
		[alert setInformativeText:NSLocalizedString(@"Deleting this Project will also delete its Tasks and Subtasks.", @"delete project message info")];
		[alert addButtonWithTitle:NSLocalizedString(@"Delete", @"delete project confirmation button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"delete project confirmation button")];
		
		[alert beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSModalResponse returnCode) {
			if (NSAlertFirstButtonReturn == returnCode) {
				[DMCurrentManagedObjectContext deleteObject:selectedProject];
			}
		}];
	}
	else {
		for (Task *task in selectedTasks) {
			[DMCurrentManagedObjectContext deleteObject:task];
		}
	}
}

- (IBAction)duplicate:(id)sender
{
	Task *selectedTask = (Task *)[DMCurrentManagedObjectContext objectWithUUID:[self.selectedTasks anyObject]];
	Project *selectedProject = (Project *)[DMCurrentManagedObjectContext objectWithUUID:self.selectedProject];
	
	if (selectedProject) {
		NSManagedObject *cloned = WSCloneManagedObjectInContext(selectedProject, DMCurrentManagedObjectContext, NO);
		[selectedProject.dayMap addProjectsObject:(Project *)cloned];
	}
	else if (selectedTask) {
		NSManagedObject *cloned = WSCloneManagedObjectInContext(selectedTask, DMCurrentManagedObjectContext, NO);
		[selectedTask.parent addChildrenObject:(AbstractTask *)cloned];
	}
}

- (IBAction)showAboutPanel:(id)sender {
	[self.aboutController showAboutPanel:sender];
}

- (IBAction)showPreferences:(id)sender
{
	if (!_preferencesWindowController) {
		_preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
	_preferencesWindowController.showAdvancedPrefs = NO;
	[_preferencesWindowController showWindow:self];
}

- (IBAction)showAdvancedPreferences:(id)sender
{
	if (!_preferencesWindowController) {
		_preferencesWindowController = [[PreferencesWindowController alloc] init];
	}
	_preferencesWindowController.showAdvancedPrefs = YES;
	[_preferencesWindowController showWindow:self];
}

- (void)preferencesClosed
{
	_preferencesWindowController = nil;
}

- (IBAction)showQuickAdd:(id)sender
{
	if (!_quickAddWindowController) {
		_quickAddWindowController = [[QuickAddWindowController alloc] init];
	}

    [NSApp activateIgnoringOtherApps:YES];
	
	[[_quickAddWindowController window] makeKeyAndOrderFront:self];
}

- (void)quickAddClosed
{
	_quickAddWindowController = nil;
}

- (IBAction)indentSelectedTasks:(id)sender 
{
	NSArray *selectedTasks = [[DMCurrentManagedObjectContext objectsWithUUIDs:self.selectedTasks] sortedArrayUsingDescriptors:SORT_BY_SORTINDEX];
	
	if (selectedTasks.count == 0) {
		return;
	}
	
	// Get parent, and validate some things
	AbstractTask *parent = [((Task *)[selectedTasks objectAtIndex:0]) parent];
	for (Task *task in selectedTasks) {
		if (nil == task.parent) {
			NSBeep();
			return; // sumpthn' broken
		}
		
		if (task.parent == DMCurrentManagedObjectContext.dayMap.inbox) {
			NSBeep();
			return; // Don't allow this in inbox
		}
		
		if (parent != task.parent) {
			NSBeep();
			return; // not all of same parent
		}
	}
	
	// get array of siblings
	NSSet *siblings = nil;
	siblings = [parent valueForKey:@"children"];
	
	// Find the sibling above the task
	NSArray *filteredSiblings = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(siblings, self.completedDateFilter, nil, SORT_BY_SORTINDEX);
	NSUInteger index = [filteredSiblings indexOfObject:[selectedTasks objectAtIndex:0]];
	if (NSNotFound == index || 0 == index) {
		NSBeep();
		return;
	}
	Task *aboveSibling = [filteredSiblings objectAtIndex:index - 1];
	
	
	for (Task *task in selectedTasks) {
		WSMoveTasksToParent([NSArray arrayWithObject:task], aboveSibling, -1, NO);
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DMExpandChildrenOfTaskNotification object:aboveSibling.uuid userInfo:nil];
}

- (IBAction)outdentSelectedTasks:(id)sender 
{
	NSSet *selectedTasks = [DMCurrentManagedObjectContext objectsWithUUIDs:self.selectedTasks];
	
	if (selectedTasks.count == 0) {
		return;
	}
	
	// Get parent, and validate some things
	AbstractTask *parent = [((Task *)[selectedTasks anyObject]) parent];
	for (Task *task in selectedTasks) {
		if (nil == task.parent || nil == task.parent.parent) {
			NSBeep();
			return; // sumpthn' broken
		}
		
		if (task.parent == DMCurrentManagedObjectContext.dayMap.inbox) {
			NSBeep();
			return; // Don't allow this in inbox
		}
		
		if (parent != task.parent) {
			NSBeep();
			return; // not all of same parent
		}
	}

	// Find parent task, then find grandparent and get array of siblings of parent
	NSSet *parentSiblings = [parent.parent valueForKey:@"children"];
	NSArray *filteredSiblings = WSFilterTasksCompletedBeforeDateOrOnDateWithSortDescriptors(parentSiblings, self.completedDateFilter, nil, SORT_BY_SORTINDEX);

	for (Task *task in selectedTasks) {
		// Find the sibling below the parent
		NSInteger index = [filteredSiblings indexOfObject:task.parent] + 1;
		WSMoveTasksToParent([NSArray arrayWithObject:task], task.parent.parent, index, NO);
	}
}

- (IBAction)printAllProjects:(id)sender
{
	_printView = [[PrintView alloc] init];
	[_printView printProjects:[DMCurrentManagedObjectContext.dayMap.projects sortedArrayUsingDescriptors:SORT_BY_SORTINDEX] completionHandler:^{
		_printView = nil; // don't want nasty web views hogging memory
	}];
}

- (IBAction)printSelectedProjects:(id)sender
{
	NSManagedObject *selectedProject = [DMCurrentManagedObjectContext objectWithUUID:self.selectedProject];
	if (!selectedProject) {
		NSBeep();
		return;
	}
	
	_printView = [[PrintView alloc] init];
	[_printView printProjects:[NSArray arrayWithObject:selectedProject] completionHandler:^{
		_printView = nil; // don't want nasty web views hogging memory
	}];
}

- (IBAction)printCalendar:(id)sender
{
	_printView = [[PrintView alloc] init];
	NSInteger numberOfDays = 7;
	if (DMCalendarViewByMonth == self.mainWindowController.calendarViewController.calendarViewByMode) {
		numberOfDays = 7 * NUMBER_OF_WEEKS_IN_MONTH_VIEW;
	}
	[_printView printWeekAsList:self.mainWindowController.calendarViewController.week numberOfDays:numberOfDays completionHandler:^{
		_printView = nil; // don't want nasty web views hogging memory
	}];
}

- (IBAction)upgradeToFullVersion:(id)sender {
#if defined(TARGET_DAYMAP_LITE)
	[self showUpgradeFromLiteNudgeWithReason:DMUpgradeNudgeReasonOther];
#endif
}

#if defined(TARGET_DAYMAP_LITE)
- (void)showUpgradeFromLiteNudgeWithReason:(DMUpgradeNudgeReason)reason {
	if (!_upgradeNudgeWindowController) {
		_upgradeNudgeWindowController = [[UpgradeNudgeWindowController alloc] init];
	}
	_upgradeNudgeWindowController.reason = reason;
	[NSApp beginSheet:_upgradeNudgeWindowController.window modalForWindow:self.mainWindowController.window modalDelegate:self didEndSelector:nil contextInfo:NULL];
}
#endif

#pragma mark - Backup

- (IBAction)showBackupFilesDirectory:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[self backupFilesDirectory]];
}

- (void)restoreFromBackupAtURL:(NSURL *)backupURL {
	if(nil == backupURL) return;
	
	NSLog(@"Restoring from backup at URL %@", backupURL);

	//	copy file into local storage.
	//	also copy file into iCloud storage?
	
	NSURL *toURL;
	BOOL prefShouldUseiCloud = WSPrefUseICloudStorage();
	if (prefShouldUseiCloud && [self isUserLoggedIntoICloud]) {
		toURL = [self ubiquitousStoreURL];
	}
	else {
		toURL = [self localStoreURL];
	}
	
	NSError *error = nil;
	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[toURL path] isDirectory:&isDir]) {
		if (![[NSFileManager defaultManager] removeItemAtURL:toURL error:&error]) {
			NSLog(@"Failed to restore from backup at URL %@ to URL %@", backupURL, toURL);
			NSRunCriticalAlertPanel(NSLocalizedString(@"Restoration Failed", @"error dialog"),
									[NSString stringWithFormat:NSLocalizedString(@"Failed to restore backup.\n%@", @"error dialog"), [error localizedDescription]],
									NSLocalizedString(@"OK", @"error dialog"), nil, nil);
			return;
		}
	}
	if (![[NSFileManager defaultManager] copyItemAtURL:backupURL toURL:toURL error:&error]) {
		NSLog(@"Failed to restore from backup at URL %@ to URL %@", backupURL, toURL);
		NSRunCriticalAlertPanel(NSLocalizedString(@"Restoration Failed", @"error dialog"),
								[NSString stringWithFormat:NSLocalizedString(@"Failed to restore backup.\n%@", @"error dialog"), [error localizedDescription]],
								NSLocalizedString(@"OK", @"error dialog"), nil, nil);
		return;
	}

	// Continue launching
	[_recoveryWindowController.window close];
	_recoveryWindowController = nil;
	[self applicationDidFinishLaunching:nil];
}

#pragma mark - Quick Add HotKey

EventHotKeyRef	gDayMapQuickAddHotKeyRef = NULL;

// -------------------------------------------------------------------------------
//	QuickAddUIElementHotKeyHandler:
//
//	We only register for one hotkey, so if we get here we know the hotkey combo was pressed
// -------------------------------------------------------------------------------
OSStatus QuickAddUIElementHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData);
OSStatus QuickAddUIElementHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent, void *userData)
{
	// We can assume our hotkey was pressed since we only installed one global hotkey for this app
    DayMapAppDelegate *appDelegate = (__bridge DayMapAppDelegate *)userData;
	[appDelegate showQuickAdd:nil];
    return noErr;
}
/*
 OSStatus UnregisterEventHotKey (
 EventHotKeyRef inHotKey
 );
 
 OSStatus RegisterEventHotKey (
 UInt32 inHotKeyCode,
 UInt32 inHotKeyModifiers,
 EventHotKeyID inHotKeyID,
 EventTargetRef inTarget,
 OptionBits inOptions,
 EventHotKeyRef *outRef
 );
 Parameters
 
 inHotKeyCode
 The virtual key code of the hot key you want to register.
 
 inHotKeyModifiers
 The keyboard modifiers to look for. In Mac OS X v10.2 and earlier, if you do not specify a modifier key, this function returns paramErr. In Mac OS X v10.3 and later, passing 0 does not cause an error.
 
 enum {
 activeFlag                    = 1 << activeFlagBit,
 btnState                      = 1 << btnStateBit,
 cmdKey                        = 1 << cmdKeyBit,
 shiftKey                      = 1 << shiftKeyBit,
 alphaLock                     = 1 << alphaLockBit,
 optionKey                     = 1 << optionKeyBit,
 controlKey                    = 1 << controlKeyBit,
 */
// -------------------------------------------------------------------------------
//	RegisterLockUIElementHotKey:
//
//	Encapsulate registering a hot key in one location
//	and we should go ahead and lock/unlock the current UIElement as needed
// -------------------------------------------------------------------------------
static OSStatus RegisterQuickAddUIElementHotKey(void *userInfo) {
    EventTypeSpec eventType = { kEventClassKeyboard, kEventHotKeyPressed };
    InstallApplicationEventHandler(NewEventHandlerUPP(QuickAddUIElementHotKeyHandler), 1, &eventType,(void *)userInfo, NULL);
	
	NSDictionary *hotKeyDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"ShortcutRecorder quickAddShortcut"];
	if (!hotKeyDict || 0 == [hotKeyDict count] || [[hotKeyDict objectForKey:@"keyCode"] integerValue] <= 0 || [[hotKeyDict objectForKey:@"modifiers"] integerValue] <= 0) {
		return -1;
	};
	UInt32	hotKeyCode = (UInt32)[[hotKeyDict objectForKey:@"keyCode"] integerValue];
	UInt32	hotKeyModifiers = (UInt32)[[hotKeyDict objectForKey:@"modifiers"] integerValue];
    
	EventHotKeyID hotKeyID = { 'hTeD', 1 }; // we make up the ID
    return RegisterEventHotKey(hotKeyCode, hotKeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &gDayMapQuickAddHotKeyRef); // Cmd-F7 will be the key to hit
}

static void UnregisterQuickAddUIElementHotKey() {
	if (gDayMapQuickAddHotKeyRef) {
		UnregisterEventHotKey(gDayMapQuickAddHotKeyRef);
	}
}

- (void)updateQuickAddShortcut
{
#ifndef TARGET_DAYMAP_LITE
	UnregisterQuickAddUIElementHotKey();
	RegisterQuickAddUIElementHotKey((__bridge void*)self);
#endif
}

@end
