//
//  WSTestRectView.m
//  DayMap
//
//  Created by Chad Seldomridge on 12/18/13.
//  Copyright (c) 2013 Monk Software LLC. All rights reserved.
//

#import "WSTestRectView.h"
#import "MiscUtils.h"

@implementation WSTestRectView

- (void)drawRect:(NSRect)dirtyRect {
	WSDrawTestRect(self.bounds);
}

@end
