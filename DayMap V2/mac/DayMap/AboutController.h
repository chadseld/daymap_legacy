//
//  AboutController.h
//  DayMap
//
//  Created by Chad Seldomridge on 4/3/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AboutController : NSObject
@property (unsafe_unretained) IBOutlet NSPanel *aboutPanel;
@property (weak) IBOutlet NSTextField *appNameLabel;
@property (weak) IBOutlet NSTextField *versionLabel;
@property (unsafe_unretained) IBOutlet NSTextView *creditsTextView;
@property (unsafe_unretained) IBOutlet NSWindow *creditsWindow;
@property (unsafe_unretained) IBOutlet NSTextView *infoTextView;

- (IBAction)showAboutPanel:(id)sender;
- (IBAction)showCredits:(id)sender;
- (IBAction)closeCredits:(id)sender;

@end
