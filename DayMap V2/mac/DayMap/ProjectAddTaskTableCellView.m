//
//  ProjectAddTaskTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/10/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectAddTaskTableCellView.h"
#import "NSColor+WS.h"
#import "ProjectView.h"

@implementation ProjectAddTaskTableCellView

- (IBAction)add:(id)sender {
	[self.projectView addTask];
}

@end
