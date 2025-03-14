//
//  ProjectTaskTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskTableCellView.h"

@interface ProjectTaskTableCellView : TaskTableCellView <NSPopoverDelegate> 

@property (weak) IBOutlet NSImageView *scheduledImageView;
@property (weak) IBOutlet NSTextField *notesLabel;

@end