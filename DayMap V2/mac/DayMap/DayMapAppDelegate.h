//
//  DayMapAppDelegate.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/20/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WSRootAppDelegate.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "QuickAddWindowController.h"
#import "PrintView.h"
#import "AboutController.h"
#if defined(TARGET_DAYMAP_LITE)
#import "UpgradeNudgeWindowController.h"
#endif

@class Project;
@class Task;


@interface DayMapAppDelegate : WSRootAppDelegate <NSApplicationDelegate>

@property (strong) IBOutlet MainWindowController *mainWindowController;
@property (strong) IBOutlet AboutController *aboutController;
@property (strong) IBOutlet NSMenu *mainMenu;
@property (weak) IBOutlet NSMenuItem *aboutMenuItem;
@property (weak) IBOutlet NSMenuItem *hideMenuItem;
@property (weak) IBOutlet NSMenuItem *quitMenuItem;
@property (weak) IBOutlet NSMenuItem *upgradeToFullVersionMenuItem;
@property (weak) IBOutlet NSMenuItem *showArchivedProjectsMenuItem;
@property (weak) IBOutlet NSMenuItem *showEKEventsMenuItem;
@property (weak) IBOutlet NSMenuItem *showOptionsSeparatorMenuItem;

@property (strong) NSString *nextTaskToEdit;
@property () BOOL disableiCloudConfigurationChanges;

- (IBAction)addTask:(id)sender;
- (IBAction)addSubtask:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showAdvancedPreferences:(id)sender;
- (void)preferencesClosed;
- (IBAction)showQuickAdd:(id)sender;
- (void)quickAddClosed;
- (IBAction)indentSelectedTasks:(id)sender;
- (IBAction)outdentSelectedTasks:(id)sender;
- (IBAction)printAllProjects:(id)sender;
- (IBAction)printSelectedProjects:(id)sender;
- (IBAction)printCalendar:(id)sender;
- (IBAction)openMainWindow:(id)sender;

- (IBAction)showBackupFilesDirectory:(id)sender;
- (void)restoreFromBackupAtURL:(NSURL *)backupURL;
- (IBAction)upgradeToFullVersion:(id)sender;

//- (NSArray *)projects;
- (void)updateQuickAddShortcut;

#if defined(TARGET_DAYMAP_LITE)
- (void)showUpgradeFromLiteNudgeWithReason:(DMUpgradeNudgeReason)reason;
#endif

@end
