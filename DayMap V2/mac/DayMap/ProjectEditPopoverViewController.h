//
//  ProjectEditPopoverViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 10/7/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Project.h"

@interface ProjectEditPopoverViewController : NSViewController <NSPopoverDelegate>

@property (nonatomic, retain) Project *project;
@property (nonatomic, strong) NSAttributedString *attributedDetails;
@property (nonatomic) BOOL archived;
@property (nonatomic, strong) NSPopover *popover;
@property (strong) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet NSColorWell *colorWell;
@property (weak) IBOutlet NSButton *expandButton;
@property (weak) IBOutlet NSButton *archiveButton;


+ (ProjectEditPopoverViewController *)projectEditPopoverViewController;

- (IBAction)expand:(id)sender;
- (IBAction)done:(id)sender;

- (NSColor *)projectColor;
- (void)setProjectColor:(NSColor *)color;

@end
