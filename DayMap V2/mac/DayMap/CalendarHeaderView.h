//
//  CalendarHeaderView.h
//  DayMap
//
//  Created by Chad Seldomridge on 3/29/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CalendarViewController;

//@protocol CalendarHeaderViewDataSource
//
//
//
//@end


@interface CalendarHeaderView : NSView

@property (strong) IBOutlet CalendarViewController *viewController;
@property (weak) IBOutlet NSView *dateSelectionContainerView;
@property (nonatomic, weak) IBOutlet NSView *contentView;

@end