//
//  MonthEKEventTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskTableCellView.h"
#import <EventKit/EKEvent.h>
#import "CalendarEKEventTableCellView.h"

@interface MonthEKEventTableCellView : CalendarEKEventTableCellView <NSPopoverDelegate>

@end