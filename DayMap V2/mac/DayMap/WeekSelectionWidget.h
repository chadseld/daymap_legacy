//
//  WeekSelectionWidget.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/7/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@protocol WeekSelectionWidgetDelegate

- (void)setWeek:(NSDate *)week;

@end


@interface SelectedWeekLayer : CALayer

@end


@interface WeekSelectionWidget : NSView

@property (nonatomic, assign) NSInteger daysDuration;

@property (strong) id delegate;
@property (nonatomic, copy) NSDate *week; 

@end
