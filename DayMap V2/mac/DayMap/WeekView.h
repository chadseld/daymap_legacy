//
//  WeekView.h
//  DayMap
//
//  Created by Chad Seldomridge on 7/6/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WeekView;


@protocol WeekViewDelegate

- (void)weekViewDidSwipeForward:(WeekView *)weekView;
- (void)weekViewDidSwipeBackward:(WeekView *)weekView;
- (void)weekViewDidScrollWheel:(NSEvent *)event;

@end


@interface WeekView : NSView

@property (assign) IBOutlet NSObject<WeekViewDelegate> *delegate;

@end
