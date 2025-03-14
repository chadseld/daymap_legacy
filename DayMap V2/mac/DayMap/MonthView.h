//
//  MonthView.h
//  DayMap
//
//  Created by Chad Seldomridge on 12/26/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MonthView;


@protocol MonthViewDelegate

- (void)monthViewDidSwipeForward:(MonthView *)monthView;
- (void)monthViewDidSwipeBackward:(MonthView *)monthView;
- (void)monthViewDidScrollWheel:(NSEvent *)event;

@end


@interface MonthView : NSView

@property (assign) IBOutlet NSObject<MonthViewDelegate> *delegate;

@property (assign) IBOutlet NSView *topHoverScrollView;
@property (assign) IBOutlet NSView *bottomHoverScrollView;

@end
