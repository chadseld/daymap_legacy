//
//  QuickAddWindowController.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/26/12.
//  Copyright (c) 2012 Whetstone Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QuickAddWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *nameField;
@property (unsafe_unretained) IBOutlet NSTextView *descriptionTextView;

- (IBAction)add:(id)sender;

@end
