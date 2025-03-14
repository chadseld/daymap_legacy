//
//  HoverScrollView.h
//  DayMap
//
//  Created by Chad Seldomridge on 9/27/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class HoverScrollView;


@protocol HoverScrollViewDelegate

- (void)hoverScrollViewIsHovering:(HoverScrollView *)hoverScrollView;

@end


@interface HoverScrollView : NSView

@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet id<HoverScrollViewDelegate> delegate;
@property (assign) NSRectEdge edge;

@end
