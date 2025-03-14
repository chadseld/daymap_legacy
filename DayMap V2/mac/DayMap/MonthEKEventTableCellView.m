//
//  MonthEKEventTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "MonthEKEventTableCellView.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"
#import "MiscUtils.h"
#import <EventKit/EventKit.h>


@implementation MonthEKEventTableCellView

- (CGFloat)fontSize {
	return [NSFont dayMapSmallListFontSize];
}

@end
