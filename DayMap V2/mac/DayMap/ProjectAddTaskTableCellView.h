//
//  ProjectAddTaskTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 11/10/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Project.h"

@class ProjectView;

@interface ProjectAddTaskTableCellView : NSTableCellView

@property (nonatomic, weak) ProjectView *projectView;

- (IBAction)add:(id)sender;

@end
