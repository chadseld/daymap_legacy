//
//  WelcomeWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/22/14.
//  Copyright (c) 2014 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WelcomeWindowController : NSWindowController
@property (weak) IBOutlet NSButton *useSampleDataCheckbox;
@property (weak) IBOutlet NSTextField *emailAddressTextField;

- (IBAction)letsGo:(id)sender;
- (IBAction)videoTour:(id)sender;

@end
