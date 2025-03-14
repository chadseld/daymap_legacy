//
//  MonthTaskTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ProjectTaskTableCellView.h"

@interface MonthTaskTableCellView : TaskTableCellView <NSPopoverDelegate> 

@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEmphasized) BOOL emphasized;

@end