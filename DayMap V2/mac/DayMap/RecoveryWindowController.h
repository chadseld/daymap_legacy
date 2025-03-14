//
//  RecoveryWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/11/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RecoveryWindowController : NSWindowController

@property (nonatomic, readonly) NSArray *backupFiles;
@property (nonatomic, readonly) NSArray *sortDescriptors;

@property (strong) IBOutlet NSArrayController *contentArrayController;
@property (strong) IBOutlet NSMenu *recoveryMenu;

- (IBAction)restore:(id)sender;

@end
