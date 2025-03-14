//
//  NSMenu+WS.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/9/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "NSMenu+WS.h"

@implementation NSMenu (NSMenu_WS)

- (void)cleanUpSeparators {
	NSMenuItem *prevVisibleItem = nil;
	for (NSMenuItem *item in self.itemArray) {
		if ([item isSeparatorItem]) {
			if ([prevVisibleItem isSeparatorItem]) {
				[item setHidden:YES];
			}
			else {
				[item setHidden:NO];
			}
		}
		if (![item isHidden]) {
			prevVisibleItem = item;
		}
	}
	for (NSMenuItem *item in self.itemArray) {
		if (![item isSeparatorItem] && ![item isHidden]) {
			break;
		}
		if ([item isSeparatorItem]) {
			[item setHidden:YES];
		}
	}
	for(NSInteger i = self.numberOfItems - 1; i >= 0; i--) {
		NSMenuItem *item = [self itemAtIndex:i];
		if (![item isSeparatorItem] && ![item isHidden]) {
			break;
		}
		if ([item isSeparatorItem]) {
			[item setHidden:YES];
		}
	}
}

@end
