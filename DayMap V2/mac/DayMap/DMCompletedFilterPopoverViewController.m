//
//  DMCompletedFilterPopoverViewController.m
//  DayMap
//
//  Created by Chad Seldomridge on 10/14/14.
//  Copyright (c) 2014 Whetstone Apps. All rights reserved.
//

#import "DMCompletedFilterPopoverViewController.h"

@interface DMCompletedFilterPopoverViewController ()

@property (nonatomic, strong) NSPopover *popover;
@property (weak) IBOutlet NSTextField *completedLabel;

@end

@implementation DMCompletedFilterPopoverViewController

+ (DMCompletedFilterPopoverViewController *)sharedController
{
	static id __controller;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__controller = [[self alloc] initWithNibName:@"DMCompletedFilterPopover" bundle:nil];
		
	});
	return __controller;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_HIDE_COMPLETED_INTERVAL options:0 context:(__bridge void*)self];
	}
	
	return self;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_HIDE_COMPLETED_INTERVAL context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[self updateLabel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == (__bridge void*)self) {
		if ([keyPath isEqualToString:PREF_HIDE_COMPLETED_INTERVAL]) {
			[self updateLabel];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)updateLabel {
	NSInteger interval = [[NSUserDefaults standardUserDefaults] integerForKey:PREF_HIDE_COMPLETED_INTERVAL];
	switch (interval) {
  case 0:
			self.completedLabel.stringValue = NSLocalizedString(@"Hide all completed", @"hide completed popover");
			break;
  case 1:
			self.completedLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Hide completed after %ld day", @"hide completed popover. Singular."), interval];
			break;
  case 91:
			self.completedLabel.stringValue = NSLocalizedString(@"Don't hide completed", @"hide completed popover");
			break;
  default:
			self.completedLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Hide completed after %ld days", @"hide completed popover. Plural."), interval];
			break;
	}
}

- (void)showFromView:(NSView *)view {
	if (self.popover) {
		return;
	}
	self.popover = [[NSPopover alloc] init];
	self.popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
	self.popover.behavior = NSPopoverBehaviorTransient;
	self.popover.animates = YES;
	self.popover.contentViewController = self;
	self.popover.delegate = self;
	
	[self.popover showRelativeToRect:view.bounds ofView:view preferredEdge:CGRectMaxYEdge];
}

- (void)hide {
	[self.popover close];
}

- (void)popoverDidClose:(NSNotification *)notification {
	NSPopover *popover = [notification object];
	popover.contentViewController = nil;
	self.popover = nil;
}

@end
