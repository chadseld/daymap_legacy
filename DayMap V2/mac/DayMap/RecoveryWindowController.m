//
//  RecoveryWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/11/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "RecoveryWindowController.h"
#import "DayMapAppDelegate.h"
#import "DayMapManagedObjectContext.h"

@interface RecoveryWindowController ()
@property (nonatomic, readwrite) NSArray *backupFiles;
@property (nonatomic, readwrite) NSArray *sortDescriptors;
@end

@implementation RecoveryWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"RecoveryWindow"];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[NSApp setMainMenu:self.recoveryMenu];
	
	self.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationdate" ascending:NO]];
	self.backupFiles = [DayMapManagedObjectContext existingBackupFilesAtURL:[(DayMapAppDelegate *)[NSApp delegate] backupFilesDirectory]];
}

- (void)windowWillClose:(NSNotification *)notification {
	self.window.delegate = nil;
	[(DayMapAppDelegate *)[NSApp delegate] applicationDidFinishLaunching:nil];
}

- (IBAction)showBackupFilesDirectory:(id)sender {
	[((DayMapAppDelegate *)[NSApp delegate]) showBackupFilesDirectory:sender];
}

- (IBAction)restore:(id)sender {
	NSInteger confirm = NSRunAlertPanel(NSLocalizedString(@"Overwrite DayMap data?", @"error dialog"),
										NSLocalizedString(@"Overwrite your existing DayMap and restore with data from the selected backup?\nThis can not be undone.", @"error dialog"),
										NSLocalizedString(@"Cancel", @"error dialog"), NSLocalizedString(@"Overwrite and Restore", @"error dialog"), nil);

	if (NSAlertAlternateReturn != confirm) {
		return;
	}
	
	NSDictionary *backup = [[self.contentArrayController selectedObjects] lastObject];
	NSLog(@"Restoring from %@", backup);
	[(DayMapAppDelegate *)[NSApp delegate] restoreFromBackupAtURL:backup[@"url"]];
}

@end
