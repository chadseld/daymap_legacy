//
//  UpgradeNudgeWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/21/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import "UpgradeNudgeWindowController.h"

@interface UpgradeNudgeWindowController ()

@end

@implementation UpgradeNudgeWindowController

- (id)init {
    self = [super initWithWindowNibName:@"UpgradeNudgeWindow"];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
	[[self window] setPreventsApplicationTerminationWhenModal:NO];
}

- (void)setReason:(DMUpgradeNudgeReason)reason {
	[self window];

	if (DMUpgradeNudgeReasonICloud == reason) {
		self.reasonTextField.stringValue = NSLocalizedString(@"Purchase the full version of DayMap to enjoy iCloud sync between your Mac and iOS devices as well as...", @"Upgrade reason");
	}
	else if (DMUpgradeNudgeReasonOther == reason) {
		self.reasonTextField.stringValue = NSLocalizedString(@"Purchase the full version of DayMap to enjoy features such as...", @"Upgrade reason");
	}
}

- (IBAction)purchaseNow:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:DMMacAppStoreURL];
	[NSApp endSheet:self.window];
	[self.window orderOut:nil];
}

- (IBAction)notNow:(id)sender {
	[NSApp endSheet:self.window];
	[self.window orderOut:nil];
}

- (IBAction)moreInformation:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:DMWhetstoneAppsURL];
	[NSApp endSheet:self.window];
	[self.window orderOut:nil];
}

@end
