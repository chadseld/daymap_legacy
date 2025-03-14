//
//  PreferencesWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 1/5/12.
//  Copyright (c) 2012 Whetstone Apps, LLC All rights reserved.
//

#import "PreferencesWindowController.h"
#import "DayMapAppDelegate.h"
#import "MiscUtils.h"
#import "UpgradeNudgeWindowController.h"

@implementation PreferencesWindowController {
#if defined(TARGET_DAYMAP_LITE)
	UpgradeNudgeWindowController *_upgradeNudgeWindowController;
#endif
}

- (id)init
{
    self = [super initWithWindowNibName:@"PreferencesWindow"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

	// Quick Add
	[self.quickAddShortcutRecorder setAutosaveName:@"quickAddShortcut"];
	[self.quickAddShortcutRecorder setAllowsKeyOnly:NO escapeKeysRecord:NO];
	[self.quickAddShortcutRecorder setAnimates:YES];
	[self.quickAddShortcutRecorder setDelegate:self];
	[self.quickAddShortcutRecorder setStyle:SRGreyStyle];
    
	// iCloud
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_ICLOUD_STORAGE options:0 context:(__bridge void*)self];
	[self.toggleiCloudButton setState:WSPrefUseICloudStorage()];
}

- (void)showWindow:(id)sender {
	[self window]; // load xib
#ifdef TARGET_DAYMAP_LITE
	[self.liteWindow makeKeyAndOrderFront:self];
#else
	[[self window] makeKeyAndOrderFront:self];
#endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_USE_ICLOUD_STORAGE]) {
			[self.toggleiCloudButton setState:WSPrefUseICloudStorage()];
		} 		
	}
	else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self.window makeFirstResponder:nil];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_ICLOUD_STORAGE];

	[(DayMapAppDelegate *)[NSApp delegate] preferencesClosed];
}

- (IBAction)toggleiCloud:(id)sender
{
#if defined(TARGET_DAYMAP_LITE)
	[self showUpgradeFromLiteNudgeWithReason:DMUpgradeNudgeReasonICloud];
	[self.toggleiCloudButton setState:NSOffState];
#else
	[(DayMapAppDelegate *)[NSApp delegate] toggleiCloud:sender];
	[self.toggleiCloudButton setState:WSPrefUseICloudStorage()];
#endif
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo 
{
	// must dispatch later so that the pref gets set
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^(void){
		[(DayMapAppDelegate *)[NSApp delegate] updateQuickAddShortcut];
	});
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
	NSWindow *window = [self window];
#ifdef TARGET_DAYMAP_LITE
	window = self.liteWindow;
#endif
	[NSApp beginSheet:_upgradeNudgeWindowController.window modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
}
#endif

@end
