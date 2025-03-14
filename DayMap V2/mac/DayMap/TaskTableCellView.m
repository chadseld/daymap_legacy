//
//  TaskTableCellView.m
//  DayMap
//
//  Created by Chad Seldomridge on 3/22/11.
//  Copyright 2012 Whetstone Apps, LLC. All rights reserved.
//

#import "TaskTableCellView.h"
#import "TaskEditPopoverViewController.h"
#import "NSColor+WS.h"
#import "NSFont+WS.h"
#import "AbstractTask+Additions.h"
#import "ProjectDisplayAttributes+Additions.h"


@interface TaskTableCellView () {
	NSColor *_projectColor;
}

- (void)showPopover;

@end


@implementation TaskTableCellView

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS context:(__bridge void*)self];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:PREF_USE_HIGH_CONTRAST_FONTS options:0 context:(__bridge void*)self];
	self.titleLabel.font = [NSFont dayMapListFontOfSize:[self fontSize]];
}

- (CGFloat)fontSize {
	return [NSFont dayMapListFontSize];
}

- (NSColor *)textColor {
	return [NSColor dayMapTaskTextColor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void*)self) {
        if ([keyPath isEqualToString:PREF_USE_HIGH_CONTRAST_FONTS]) {
			self.titleLabel.font = [NSFont dayMapListFontOfSize:[self fontSize]];
			NSString *s = self.titleLabel.stringValue;
			self.titleLabel.stringValue = @"";
			self.titleLabel.stringValue = s;
		}
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)resetCursorRects
{
//    [self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent]; // TableView takes over from here
                                // Don't expect to see any mouseDragged or mouseUp
    if (theEvent.clickCount == 2) {
        [self showPopover];
    }
}

- (void)updateToolTip
{
    self.toolTip = self.task.name;
	if (self.task.attributedDetails) self.toolTip = [[self.task.name stringByAppendingString:@"\n----\n"] stringByAppendingString:[self.task.attributedDetailsAttributedString string]];
}

- (void)showPopover
{
    if(![self window]) return;
    
    NSPopover *popover = [[NSPopover alloc] init];
	popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    popover.behavior = NSPopoverBehaviorSemitransient;
    popover.animates = YES;
    
    TaskEditPopoverViewController *viewController = [TaskEditPopoverViewController taskEditPopoverViewController];
    viewController.popover = popover;
	viewController.shownForDay = self.day;
    viewController.task = self.task;
    popover.contentViewController = viewController;
	popover.delegate = viewController;
 
	// Show relative to a superview because sometimes when we change a task property
	// the table view reloads and our cell view (self) is replaced -- which instantly
	// closes the popover.
	NSView *popoverHostView = [[self enclosingScrollView] documentView] ? : [self superview];
	[popover showRelativeToRect:[popoverHostView convertRect:self.bounds fromView:self] ofView:popoverHostView preferredEdge:CGRectMaxXEdge];
}

- (void)setTask:(Task *)task {
	_task = task;
	
	[self updateToolTip];
	
	ProjectDisplayAttributes *rootProjectAttributes = task.rootProject.displayAttributes;
	_projectColor = rootProjectAttributes ? [rootProjectAttributes nativeColor] : [NSColor blackColor];
}

- (NSBezierPath *)projectColorPath {
	return [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(3, 2, 5, self.bounds.size.height-4) xRadius:2	yRadius:2];
}

- (void)drawRect:(NSRect)dirtyRect {
	[_projectColor set];
	[[self projectColorPath] fill];
}

@end
