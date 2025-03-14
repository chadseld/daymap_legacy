//
//  ProjectViewController.h
//  DayMap
//
//  Created by Chad Seldomridge on 2/21/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Project.h"
#import "ProjectView.h"
#import "ProjectTableHeaderView.h"
#import "CascadingHorizontalOnlyScrollView.h"

@interface ProjectsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, DMProjectTableViewDelegate>

@property (weak) IBOutlet CascadingHorizontalOnlyScrollView *scrollView;
@property (weak) IBOutlet NSTableView *tableView;

- (void)update;
- (IBAction)addProject:(id)sender;
- (void)showProjectEditPopover:(Project *)project;

@end
