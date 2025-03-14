//
//  PreferencesWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 1/5/12.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShortcutRecorder.h"

@interface PreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSButton *toggleiCloudButton;
@property (weak) IBOutlet SRRecorderControl *quickAddShortcutRecorder;
@property () BOOL showAdvancedPrefs;
@property (strong) IBOutlet NSWindow *liteWindow;

@end
