//
//  WelcomeWindowController.m
//  DayMap
//
//  Created by Chad Seldomridge on 2/22/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import "WelcomeWindowController.h"

@interface WelcomeWindowController ()

@end

@implementation WelcomeWindowController

- (id)init {
    self = [super initWithWindowNibName:@"WelcomeWindow"];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
	[[self window] setPreventsApplicationTerminationWhenModal:NO];
}

- (IBAction)letsGo:(id)sender {
	[self.window.sheetParent endSheet:self.window];
	[self.window orderOut:nil];
}

- (IBAction)videoTour:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:DMWhetstoneAppsTourURL];
}

@end
