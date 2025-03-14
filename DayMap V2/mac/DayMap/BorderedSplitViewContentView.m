//
//  BorderedSplitViewContentView.m
//  DayMap
//
//  Created by Chad Seldomridge on 11/1/11.
//  Copyright (c) 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "BorderedSplitViewContentView.h"
#import "NSColor+WS.h"

@implementation BorderedSplitViewContentView

- (BOOL)isOpaque {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor dayMapDividerColor] set];
    NSFrameRect(self.bounds);
}

@end
