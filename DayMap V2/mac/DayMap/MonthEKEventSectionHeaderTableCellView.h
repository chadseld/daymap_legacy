//
//  MonthEKEventSectionHeaderTableCellView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskTableCellView.h"
#import <EventKit/EKEvent.h>
#import "CalendarEKEventSectionHeaderTableCellView.h"

@interface MonthEKEventSectionHeaderTableCellView : CalendarEKEventSectionHeaderTableCellView <NSPopoverDelegate>

@end