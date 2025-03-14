//
//  ProjectView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/2/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Project.h"

@interface ProjectView : NSView <NSOutlineViewDelegate, NSOutlineViewDataSource, NSMenuDelegate>

@property (nonatomic, strong) Project *project;
@property (nonatomic) BOOL isInbox;
@property (nonatomic) BOOL minimized;
@property (nonatomic, readonly) BOOL canExpandAll;
@property (nonatomic, readonly) BOOL canCollapseAll;

- (void)addTask;

- (void)expandAll;
- (void)collapseAll;

@end
