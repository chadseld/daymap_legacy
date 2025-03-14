//
//  MonthTaskTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "MonthTaskTableCellView.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"
#import "Task+Additions.h"


@implementation MonthTaskTableCellView

- (void)setStrikedTitle:(BOOL)striked
{
	NSString *string = self.titleLabel.stringValue;
	if(nil == string || string.length == 0) return;
	
	NSMutableAttributedString *as = [[self.titleLabel attributedStringValue] mutableCopy];
	if (striked) {
		[as addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [as length])];
		[as addAttribute:NSForegroundColorAttributeName value:[NSColor dayMapCompletedTaskTextColor] range:NSMakeRange(0, [as length])];
	}
	else {
		[as removeAttribute:NSStrikethroughStyleAttributeName range:NSMakeRange(0, [as length])];
		[as addAttribute:NSForegroundColorAttributeName value:self.textColor range:NSMakeRange(0, [as length])];
	}
	[self.titleLabel setAttributedStringValue:as];
}

- (void)dealloc {
	[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	// do nothing. Prevents system from changing color of text when selected.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:@"name"] ||
			[keyPath isEqualToString:@"completed"] ||
			[keyPath isEqualToString:@"repeat"] ||
			[keyPath isEqualToString:@"completedDate"] ||
			[keyPath isEqualToString:@"scheduledDate"] ||
			[keyPath isEqualToString:@"attributedDetails"] ||
			[keyPath isEqualToString:@"repeat.completions"] ||
			[keyPath isEqualToString:@"repeat.exceptions"]) {
			if (self.task) {
				[self.titleLabel setStringValue:self.task.name ? : @""];
				//				self.textColor = [self.task.parent.entity.name isEqualToString:@"Task"] ? [NSColor colorWithDeviceWhite:0.0 alpha:0.75] : [NSColor colorWithDeviceWhite:0.0 alpha:1];
				[self setStrikedTitle:[self.task isCompletedAtDate:self.day partial:nil]];
				[self updateToolTip];
				[self.superview setNeedsDisplay:YES];
			}
		}
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
			if (self.task) {
				[self setStrikedTitle:[self.task isCompletedAtDate:self.day partial:nil]];
			}
		}
		else {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self observeValueForKeyPath:@"name" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (void)setTask:(Task *)task
{
	if (task == self.task) {
		return;
	}
	
	[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];
	
	[super setTask:task];
	
	[self.task addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"completed" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"repeat" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"completedDate" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"scheduledDate" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"attributedDetails" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"repeat.completions" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"repeat.exceptions" options:0 context:(__bridge void*)self];
	
	[self observeValueForKeyPath:@"name" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (NSColor *)textColor {
	return [NSColor dayMapDarkTextColor];
}

- (CGFloat)fontSize {
	return [NSFont dayMapSmallListFontSize];
}

- (NSBezierPath *)projectColorPath {
	return [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(5, 2, 4, self.bounds.size.height-4) xRadius:1.8 yRadius:1.8];
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
	if (self.highlighted) {
		if (self.window.isKeyWindow && self.emphasized) {
			[[NSColor selectedControlColor] set];
		}
		else {
			[[NSColor secondarySelectedControlColor] set];
		}
		NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	}
	[super drawRect:dirtyRect];
}

- (NSView *)hitTest:(NSPoint)aPoint {return nil;}

@end
