//
//  CalendarTaskTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "CalendarTaskTableCellView.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "NSColor+WS.h"
#import "MiscUtils.h"


@implementation CalendarTaskTableCellView

- (void)dealloc {
    [self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[super awakeFromNib];
}

- (NSColor *)textColor {
	return [NSColor dayMapDarkTextColor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:@"name"] ||
			[keyPath isEqualToString:@"completed"] ||
			[keyPath isEqualToString:@"repeat.completions"] ||
			[keyPath isEqualToString:@"repeat.exceptions"] ||
			[keyPath isEqualToString:@"attributedDetails"] ||
			[keyPath isEqualToString:@"completedDate"]) {

			BOOL partial = NO;
			BOOL complete = [self.task isCompletedAtDate:self.day partial:&partial];
			if (partial) {
				[self.completedCheckbox setState:NSMixedState];
			}
			else {
				[self.completedCheckbox setState:complete ? NSOnState : NSOffState];
			}

            [self updateToolTip];
			[self.superview setNeedsDisplay:YES];
        }
		else {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	// do nothing. Prevents system from changing color of text when selected.
}

- (void)setTask:(Task *)task
{
    [self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];

    [super setTask:task];
	
    [self.task addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"completed" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"completedDate" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"attributedDetails" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"repeat.completions" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"repeat.exceptions" options:0 context:(__bridge void*)self];

    [self observeValueForKeyPath:@"completed" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (IBAction)toggleCompleted:(id)sender
{
	[self.task toggleCompletedAtDate:self.day partial:WSIsOptionKeyPressed()];
}

- (BOOL)isOpaque {
	return NO;
}

@end
