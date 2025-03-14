//
//  MonthDayView.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Task.h"


@interface MonthDayView : NSView

@property (nonatomic, weak) IBOutlet id delegate;
@property (nonatomic, weak) IBOutlet id dataSource;
@property (nonatomic, strong) NSDate *day;

- (void)reloadData;
- (void)updateSelection:(NSSet *)selectedTaskIds;

@end


@protocol MonthDayViewDataSource

- (NSInteger)numberOfRowsInMonthDayView:(MonthDayView *)monthDayView;
- (NSTableCellView *)monthDayView:(MonthDayView *)monthDayView viewForRow:(NSInteger)row;

@end


@protocol MonthDayViewDelegate

- (BOOL)monthDayView:(MonthDayView *)monthDayView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard;
- (BOOL)monthDayView:(MonthDayView *)monthDayView acceptDrop:(id <NSDraggingInfo>)info;
- (void)monthDayView:(MonthDayView *)monthDayView didSelectRowsWithIndexes:(NSIndexSet *)rowIndexes;
- (void)monthDayView:(MonthDayView *)monthDayView showWeek:(NSDate *)week;
- (void)monthDayViewAddTask:(MonthDayView *)monthDayView;
- (void)monthDayView:(MonthDayView *)monthDayView addSubtaskToTaskAtRow:(NSInteger)rowIndex;
- (void)monthDayView:(MonthDayView *)monthDayView unscheduleRowsWithIndexes:(NSIndexSet *)rowIndexes;
- (void)monthDayView:(MonthDayView *)monthDayView toggleCompletedRowsWithIndexes:(NSIndexSet *)rowIndexes;
- (void)monthDayView:(MonthDayView *)monthDayView showInOutlineViewRowWithIndex:(NSInteger)rowIndex;
- (void)monthDayViewDidChangeResponderStatus:(MonthDayView *)monthDayView;

@end