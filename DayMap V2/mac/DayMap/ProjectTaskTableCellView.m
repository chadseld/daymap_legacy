//
//  ProjectTaskTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "ProjectTaskTableCellView.h"
#import "NSColor+WS.h"
#import "Task+Additions.h"
#import "AbstractTask+Additions.h"
#import "RecurrenceRule+Additions.h"


@implementation ProjectTaskTableCellView

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
	[self.task removeObserver:self forKeyPath:@"repeat.frequency" context:(__bridge void*)self];
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
		if ([keyPath isEqualToString:@"attributedDetails"]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:DMResizeRowForTaskNotification object:self.task.uuid];
		}
        if ([keyPath isEqualToString:@"name"] ||
			[keyPath isEqualToString:@"completed"] ||
			[keyPath isEqualToString:@"repeat"] ||
			[keyPath isEqualToString:@"repeat.frequency"] ||
			[keyPath isEqualToString:@"completedDate"] ||
			[keyPath isEqualToString:@"scheduledDate"] ||
			[keyPath isEqualToString:@"attributedDetails"] ||
			[keyPath isEqualToString:@"repeat.completions"] ||
			[keyPath isEqualToString:@"repeat.exceptions"]) {
			if (self.task) {
				[self.titleLabel setStringValue:self.task.name ? : @""];
//				self.textColor = [self.task.parent.entity.name isEqualToString:@"Task"] ? [NSColor colorWithDeviceWhite:0.0 alpha:0.75] : [NSColor colorWithDeviceWhite:0.0 alpha:1];
			
				BOOL completedAtDay = [self.task isCompletedAtDate:self.day partial:nil];
				self.scheduledImageView.image = completedAtDay ? [NSImage imageNamed:@"scheduled_completed"] : [NSImage imageNamed:@"scheduled"];
				[self.scheduledImageView setHidden:(nil == self.task.scheduledDate)];
				[self.notesLabel setHidden:(nil == self.task.attributedDetails || ![[NSUserDefaults standardUserDefaults] boolForKey:PREF_SHOW_NOTES_IN_OUTLINE])];
				self.notesLabel.stringValue = [self.task.attributedDetailsAttributedString string] ? : @"";
				[self setStrikedTitle:completedAtDay];
                [self updateToolTip];
				[self.superview setNeedsDisplay:YES];
				[self setNeedsLayout:YES];
				[self resizeSubviewsWithOldSize:self.bounds.size];
			}
        }
		if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
			if (self.task) {
				[self setStrikedTitle:[self.task isCompletedAtDate:self.day partial:nil]];
				[self setNeedsLayout:YES];
				[self resizeSubviewsWithOldSize:self.bounds.size];
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
	[self.task removeObserver:self forKeyPath:@"name" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"completed" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.frequency" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"completedDate" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"scheduledDate" context:(__bridge void*)self];
    [self.task removeObserver:self forKeyPath:@"attributedDetails" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.completions" context:(__bridge void*)self];
	[self.task removeObserver:self forKeyPath:@"repeat.exceptions" context:(__bridge void*)self];

    [super setTask:task];

	[self.task addObserver:self forKeyPath:@"name" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"completed" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"repeat" options:0 context:(__bridge void*)self];
	[self.task addObserver:self forKeyPath:@"repeat.frequency" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"completedDate" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"scheduledDate" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"attributedDetails" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"repeat.completions" options:0 context:(__bridge void*)self];
    [self.task addObserver:self forKeyPath:@"repeat.exceptions" options:0 context:(__bridge void*)self];

    [self observeValueForKeyPath:@"name" ofObject:self.task change:nil context:(__bridge void*)self];
}

- (NSBezierPath *)projectColorPath {
	return nil;
}

- (void)updateToolTip
{
	[super updateToolTip];

	if (self.task.scheduledDate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		
		
		NSString *scheduledToolTip = [NSString stringWithFormat:@"Scheduled %@",
										   [dateFormatter stringFromDate:self.task.scheduledDate]];
		if (self.task.repeat)  {
			scheduledToolTip = [scheduledToolTip stringByAppendingFormat:@" (%@)", [self.task.repeat simpleStringDescription]];
		}
		self.scheduledImageView.toolTip = scheduledToolTip;
	}
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	const BOOL highContrastFonts = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_USE_HIGH_CONTRAST_FONTS];
	const CGFloat imageSize = 13;
	
	CGFloat imageY = self.bounds.size.height - imageSize - (highContrastFonts ? 5 : 6);
	
	self.scheduledImageView.frame = NSMakeRect(4, imageY, imageSize, imageSize);
	CGFloat scheduledMaxX = self.scheduledImageView.hidden ? 0 : NSMaxX(self.scheduledImageView.frame);
	
	if (self.notesLabel.hidden) {
		self.titleLabel.frame = NSMakeRect(scheduledMaxX + 4, 1, self.bounds.size.width - (scheduledMaxX + 4) - 4, 21);
	}
	else {
		self.notesLabel.frame = NSMakeRect(scheduledMaxX + 4, 1, self.bounds.size.width - (scheduledMaxX + 4) - 4, 17);
		self.titleLabel.frame = NSMakeRect(scheduledMaxX + 4, NSMaxY(self.notesLabel.frame) - 1, self.bounds.size.width - (scheduledMaxX + 4) - 4, 21);

	}
}

@end
